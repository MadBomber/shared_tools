# frozen_string_literal: true

require "open3"
require "timeout"

module SharedTools
  # Shared subprocess runner used by BashTool and the toolchain tools
  # (BundleTool, LintTool, RunTestsTool, PythonTestsTool). Always array-form
  # (no shell), streams both pipes so a chatty child can't deadlock on a full
  # pipe buffer, and hard-kills the process if it blows the wall-clock budget.
  #
  # Returns [stdout, stderr, status] where status is a Process::Status or the
  # symbol :timeout.
  module ProcessRunner
    module_function

    def capture(argv, env: {}, stdin: nil, timeout: 30, unsetenv_others: true, chdir: nil)
      opts = { unsetenv_others: unsetenv_others }
      opts[:chdir] = chdir if chdir
      Open3.popen3(env, *argv, **opts) do |i, o, e, thr|
        write_stdin(i, stdin)
        pump(o, e, thr, timeout)
      end
    end

    def write_stdin(io, stdin)
      io.write(stdin) if stdin && !stdin.empty?
    rescue StandardError
      # Child may have exited/closed the pipe before we finished writing.
      nil
    ensure
      begin
        io.close
      rescue StandardError
        nil
      end
    end

    def pump(stdout, stderr, wait_thr, timeout)
      out = +""
      err = +""
      readers = [stdout, stderr]

      Timeout.timeout(timeout) do
        until readers.empty?
          ready, = IO.select(readers)
          ready.each do |io|
            chunk = io.read_nonblock(4096)
            (io.equal?(stdout) ? out : err) << chunk
          rescue IO::WaitReadable
            next
          rescue EOFError
            readers.delete(io)
          end
        end
        [out, err, wait_thr.value]
      end
    rescue Timeout::Error
      kill(wait_thr.pid)
      [out, err, :timeout]
    end

    def kill(pid)
      Process.kill("KILL", pid)
    rescue StandardError
      nil
    end
  end
end
