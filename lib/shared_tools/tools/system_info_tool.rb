# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools
  module Tools
    # Returns OS, CPU, memory, disk, network, and Ruby runtime information.
    #
    # @example
    #   tool = SharedTools::Tools::SystemInfoTool.new
    #   tool.execute                     # all categories
    #   tool.execute(category: 'cpu')    # CPU only
    class SystemInfoTool < ::RubyLLM::Tool
      def self.name = 'system_info_tool'

      description <<~DESC
        Retrieve system information from the local machine.

        Categories:
        - 'os'      — Operating system name, version, hostname
        - 'cpu'     — CPU model, core count, load averages
        - 'memory'  — Total and available RAM in GB
        - 'disk'    — Mounted filesystems with used/available space
        - 'network' — Active network interfaces and their IP addresses
        - 'ruby'    — Ruby version, platform, engine, RubyGems version
        - 'all'     (default) — All of the above combined
      DESC

      params do
        string :category, required: false, description: <<~DESC.strip
          Info category. Options: 'os', 'cpu', 'memory', 'disk', 'network', 'ruby', 'all' (default).
        DESC
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param category [String] which subsystem to query
      # @return [Hash] system information
      def execute(category: 'all')
        @logger.info("SystemInfoTool#execute category=#{category}")

        case category.to_s.downcase
        when 'os'      then { success: true }.merge(os_info)
        when 'cpu'     then { success: true }.merge(cpu_info)
        when 'memory'  then { success: true }.merge(memory_info)
        when 'disk'    then { success: true }.merge(disk_info)
        when 'network' then { success: true }.merge(network_info)
        when 'ruby'    then { success: true }.merge(ruby_info)
        else
          { success: true }
            .merge(os_info)
            .merge(cpu_info)
            .merge(memory_info)
            .merge(disk_info)
            .merge(network_info)
            .merge(ruby_info)
        end
      rescue => e
        @logger.error("SystemInfoTool error: #{e.message}")
        { success: false, error: e.message }
      end

      private

      def os_info
        {
          os_platform: RUBY_PLATFORM,
          os_name:     detect_os_name,
          os_version:  detect_os_version,
          hostname:    `hostname`.strip
        }
      end

      def cpu_info
        if RUBY_PLATFORM.include?('darwin')
          model  = `sysctl -n machdep.cpu.brand_string 2>/dev/null`.strip
          cores  = `sysctl -n hw.ncpu 2>/dev/null`.strip.to_i
          load   = `sysctl -n vm.loadavg 2>/dev/null`.strip
                     .gsub(/[{}]/, '').split.first(3).map(&:to_f)
        else
          model  = File.read('/proc/cpuinfo')
                     .match(/model name\s*:\s*(.+)/)&.captures&.first&.strip rescue 'Unknown'
          cores  = `nproc 2>/dev/null`.strip.to_i
          load   = File.read('/proc/loadavg').split.first(3).map(&:to_f) rescue [0.0, 0.0, 0.0]
        end

        {
          cpu_model:      model.empty? ? 'Unknown' : model,
          cpu_cores:      cores,
          load_avg_1m:    load[0],
          load_avg_5m:    load[1],
          load_avg_15m:   load[2]
        }
      end

      def memory_info
        if RUBY_PLATFORM.include?('darwin')
          total    = `sysctl -n hw.memsize 2>/dev/null`.strip.to_i
          vm_stat  = `vm_stat 2>/dev/null`
          pg_size  = vm_stat.match(/page size of (\d+) bytes/)&.captures&.first&.to_i || 4096
          free_pg  = vm_stat.match(/Pages free:\s+(\d+)/)&.captures&.first&.to_i || 0
          inact_pg = vm_stat.match(/Pages inactive:\s+(\d+)/)&.captures&.first&.to_i || 0
          available = (free_pg + inact_pg) * pg_size
        else
          mem = File.read('/proc/meminfo') rescue ''
          total     = (mem.match(/MemTotal:\s+(\d+) kB/)&.captures&.first&.to_i || 0) * 1024
          available = (mem.match(/MemAvailable:\s+(\d+) kB/)&.captures&.first&.to_i || 0) * 1024
        end

        gb = 1024.0**3
        {
          memory_total_gb:     (total     / gb).round(2),
          memory_available_gb: (available / gb).round(2),
          memory_used_gb:      ((total - available) / gb).round(2)
        }
      end

      def disk_info
        lines  = `df -k 2>/dev/null`.lines.drop(1)
        mounts = lines.filter_map do |line|
          parts = line.split
          next unless parts.size >= 6

          kb = 1024.0**2
          {
            filesystem:    parts[0],
            mount_point:   parts[5],
            size_gb:       (parts[1].to_i / kb).round(2),
            used_gb:       (parts[2].to_i / kb).round(2),
            available_gb:  (parts[3].to_i / kb).round(2),
            use_percent:   parts[4]
          }
        end
        { disks: mounts }
      end

      def network_info
        interfaces = {}

        if RUBY_PLATFORM.include?('darwin')
          current = nil
          `ifconfig 2>/dev/null`.lines.each do |line|
            if (m = line.match(/^(\w[\w:]+\d+):/))
              current = m.captures.first
              interfaces[current] = []
            elsif current && (m = line.match(/\s+inet6?\s+(\S+)/))
              addr = m.captures.first.split('%').first
              interfaces[current] << addr
            end
          end
        else
          current = nil
          `ip addr 2>/dev/null`.lines.each do |line|
            if (m = line.match(/^\d+: (\w+):/))
              current = m.captures.first
              interfaces[current] = []
            elsif current && (m = line.match(/\s+inet6?\s+(\S+)/))
              interfaces[current] << m.captures.first.split('/').first
            end
          end
        end

        { network_interfaces: interfaces.reject { |_, ips| ips.empty? } }
      end

      def ruby_info
        {
          ruby_version:      RUBY_VERSION,
          ruby_platform:     RUBY_PLATFORM,
          ruby_engine:       RUBY_ENGINE,
          ruby_description:  RUBY_DESCRIPTION,
          rubygems_version:  Gem::VERSION
        }
      end

      def detect_os_name
        if RUBY_PLATFORM.include?('darwin')
          `sw_vers -productName 2>/dev/null`.strip
        elsif File.exist?('/etc/os-release')
          File.read('/etc/os-release').match(/^NAME="?([^"\n]+)"?/)&.captures&.first || 'Linux'
        else
          'Unknown'
        end
      rescue
        'Unknown'
      end

      def detect_os_version
        if RUBY_PLATFORM.include?('darwin')
          `sw_vers -productVersion 2>/dev/null`.strip
        elsif File.exist?('/etc/os-release')
          File.read('/etc/os-release').match(/^VERSION="?([^"\n]+)"?/)&.captures&.first || 'Unknown'
        else
          'Unknown'
        end
      rescue
        'Unknown'
      end
    end
  end
end
