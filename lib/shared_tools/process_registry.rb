# frozen_string_literal: true

require "open3"

module SharedTools
  # A single managed background process, used by ProcessRegistry. Its stdout
  # and stderr are drained continuously by reader threads into bounded
  # buffers, so a chatty child can't deadlock on a full pipe or grow memory
  # without limit. Output is read incrementally (each read returns only what's
  # new since the last one). The child runs in its own process group so it —
  # and any children it spawns — can be killed together.
  class ManagedProcess
    MAX_BUFFER = 256 * 1024 # retain at most this many unread bytes per stream

    attr_reader :id, :name, :argv, :pid, :started_at

    def initialize(id:, argv:, env:, chdir:, name:)
      @id = id
      @argv = argv
      @name = name
      @started_at = Time.now
      @mutex = Mutex.new
      @out = +""
      @err = +""
      @out_dropped = false
      @err_dropped = false

      opts = { unsetenv_others: true, pgroup: true }
      opts[:chdir] = chdir if chdir && !chdir.to_s.empty?

      stdin, stdout, stderr, @wait_thr = Open3.popen3(env, *argv, **opts)
      @pid = @wait_thr.pid
      begin
        stdin.close
      rescue StandardError
        nil
      end

      @readers = [drain(stdout, :out), drain(stderr, :err)]
    end

    def running?
      @wait_thr.alive?
    end

    def status
      running? ? :running : :exited
    end

    def exit_code
      return nil if running?

      @wait_thr.value.exitstatus
    rescue StandardError
      nil
    end

    def age
      Time.now - @started_at
    end

    # Returns and clears the output accumulated since the previous call.
    def read_new
      @mutex.synchronize do
        data = { out: @out.dup, err: @err.dup, out_dropped: @out_dropped, err_dropped: @err_dropped }
        @out = +""
        @err = +""
        @out_dropped = false
        @err_dropped = false
        data
      end
    end

    # SIGTERM the whole tree, escalate to SIGKILL after a grace period.
    # Descendants are collected up front (before the parent dies and they get
    # reparented), then signalled both via the process group and individually
    # — so cleanup is reliable even in sandboxes that don't deliver
    # process-group signals to non-leader members.
    def kill(grace: 2.0)
      return unless @wait_thr.alive?

      targets = [@pid] + descendants(@pid)
      signal_group("TERM")
      targets.each { |pid| signal_pid(pid, "TERM") }

      deadline = Time.now + grace
      sleep(0.05) while @wait_thr.alive? && Time.now < deadline

      signal_group("KILL")
      targets.each { |pid| signal_pid(pid, "KILL") }
      begin
        @wait_thr.value
      rescue StandardError
        nil
      end
    end

    private

    def signal_group(sig)
      Process.kill("-#{sig}", @pid) # negative pid => the process group
    rescue StandardError
      nil
    end

    def signal_pid(pid, sig)
      Process.kill(sig, pid)
    rescue StandardError
      nil
    end

    # All transitive children of root, via /proc (Linux). Collected before the
    # parent is killed, so the parent->child links are still intact. No-ops
    # (returns []) on hosts without /proc, e.g. macOS.
    def descendants(root)
      return [] unless File.directory?("/proc")

      children = Hash.new { |h, k| h[k] = [] }
      Dir.glob("/proc/[0-9]*/stat").each do |file|
        data = File.read(file)
        open_paren = data.index("(")
        close_paren = data.rindex(")")
        next unless open_paren && close_paren

        pid = data[0...open_paren].to_i
        ppid = data[(close_paren + 2)..].to_s.split[1].to_i
        children[ppid] << pid
      rescue StandardError
        next
      end

      result = []
      queue = children[root].dup
      until queue.empty?
        pid = queue.shift
        next if result.include?(pid)

        result << pid
        queue.concat(children[pid])
      end
      result
    end

    def drain(io, which)
      Thread.new do
        loop do
          append(which, io.readpartial(4096))
        end
      rescue EOFError, IOError
        nil
      ensure
        begin
          io.close
        rescue StandardError
          nil
        end
      end
    end

    def append(which, chunk)
      @mutex.synchronize do
        buf = which == :out ? @out : @err
        buf << chunk
        next unless buf.bytesize > MAX_BUFFER

        overflow = buf.bytesize - MAX_BUFFER
        buf.replace(buf.byteslice(overflow, MAX_BUFFER) || +"")
        if which == :out
          @out_dropped = true
        else
          @err_dropped = true
        end
      end
    end
  end

  # Thread-safe registry of background processes, shared across tool calls
  # within a process. Holds an upper bound on concurrent live processes and
  # cleans everything up at interpreter exit so nothing is orphaned.
  module ProcessRegistry
    class LimitError < StandardError; end

    @mutex = Mutex.new
    @procs = {}
    @counter = 0

    class << self
      def start(argv:, env:, chdir:, name:, max: 8)
        @mutex.synchronize do
          live = @procs.values.count(&:running?)
          raise LimitError, "too many background processes (limit #{max}); kill some first" if live >= max

          @counter += 1
          id = "proc_#{@counter}"
          @procs[id] = ManagedProcess.new(id: id, argv: argv, env: env, chdir: chdir, name: name)
          id
        end
      end

      def get(id)
        @mutex.synchronize { @procs[id] }
      end

      def all
        @mutex.synchronize { @procs.values.dup }
      end

      def delete(id)
        @mutex.synchronize { @procs.delete(id) }
      end

      def kill_all
        all.each { |proc| proc.kill(grace: 0.2) }
      end

      def reset!
        all.each { |proc| proc.kill(grace: 0.2) }
        @mutex.synchronize { @procs = {} }
      end
    end
  end
end

at_exit { SharedTools::ProcessRegistry.kill_all }
