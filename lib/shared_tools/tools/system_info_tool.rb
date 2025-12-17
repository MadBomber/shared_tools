# frozen_string_literal: true

require 'ruby_llm/tool'

module SharedTools
  module Tools
    # A tool for retrieving system information including OS, CPU, memory, and disk details.
    # Provides cross-platform support for macOS, Linux, and Windows.
    #
    # @example
    #   tool = SharedTools::Tools::SystemInfoTool.new
    #   result = tool.execute(category: 'all')
    #   puts result[:os][:name]        # "macOS"
    #   puts result[:memory][:total]   # "32 GB"
    class SystemInfoTool < RubyLLM::Tool
      def self.name = 'system_info'

      description <<~'DESCRIPTION'
        Retrieve system information including operating system, CPU, memory, and disk details.

        This tool provides cross-platform system information:
        - macOS: Uses system_profiler, sysctl, and df commands
        - Linux: Uses /proc filesystem and df command
        - Windows: Uses wmic and powershell commands

        Categories:
        - 'all': Returns all system information (default)
        - 'os': Operating system information only
        - 'cpu': CPU information only
        - 'memory': Memory information only
        - 'disk': Disk space information only
        - 'network': Network interface information only

        Example usage:
          tool = SharedTools::Tools::SystemInfoTool.new

          # Get all system info
          result = tool.execute(category: 'all')

          # Get specific category
          result = tool.execute(category: 'memory')
          puts result[:total]  # Total RAM
      DESCRIPTION

      params do
        string :category, description: <<~DESC.strip, required: false
          The category of system information to retrieve:
          - 'all' (default): All system information
          - 'os': Operating system details
          - 'cpu': CPU details
          - 'memory': Memory/RAM details
          - 'disk': Disk space details
          - 'network': Network interface details
        DESC
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # Execute system info retrieval
      #
      # @param category [String] category of info to retrieve
      # @return [Hash] system information
      def execute(category: 'all')
        @logger.info("SystemInfoTool#execute category=#{category.inspect}")

        case category.to_s.downcase
        when 'all'
          get_all_info
        when 'os'
          { success: true, os: get_os_info }
        when 'cpu'
          { success: true, cpu: get_cpu_info }
        when 'memory'
          { success: true, memory: get_memory_info }
        when 'disk'
          { success: true, disk: get_disk_info }
        when 'network'
          { success: true, network: get_network_info }
        else
          {
            success: false,
            error: "Unknown category: #{category}. Valid categories are: all, os, cpu, memory, disk, network"
          }
        end
      rescue => e
        @logger.error("SystemInfoTool error: #{e.message}")
        {
          success: false,
          error: e.message
        }
      end

      private

      def get_all_info
        {
          success: true,
          os: get_os_info,
          cpu: get_cpu_info,
          memory: get_memory_info,
          disk: get_disk_info,
          network: get_network_info,
          ruby: get_ruby_info
        }
      end

      def get_os_info
        case platform
        when :macos
          {
            name: 'macOS',
            version: `sw_vers -productVersion 2>/dev/null`.strip,
            build: `sw_vers -buildVersion 2>/dev/null`.strip,
            hostname: `hostname 2>/dev/null`.strip,
            kernel: `uname -r 2>/dev/null`.strip,
            architecture: `uname -m 2>/dev/null`.strip,
            uptime: parse_uptime(`uptime 2>/dev/null`.strip)
          }
        when :linux
          {
            name: get_linux_distro,
            version: get_linux_version,
            hostname: `hostname 2>/dev/null`.strip,
            kernel: `uname -r 2>/dev/null`.strip,
            architecture: `uname -m 2>/dev/null`.strip,
            uptime: parse_uptime(`uptime 2>/dev/null`.strip)
          }
        when :windows
          {
            name: 'Windows',
            version: `ver 2>nul`.strip,
            hostname: `hostname 2>nul`.strip,
            architecture: ENV['PROCESSOR_ARCHITECTURE'] || 'unknown'
          }
        else
          { name: 'unknown', platform: RUBY_PLATFORM }
        end
      end

      def get_cpu_info
        case platform
        when :macos
          {
            model: `sysctl -n machdep.cpu.brand_string 2>/dev/null`.strip,
            cores: `sysctl -n hw.ncpu 2>/dev/null`.strip.to_i,
            physical_cores: `sysctl -n hw.physicalcpu 2>/dev/null`.strip.to_i,
            architecture: `uname -m 2>/dev/null`.strip,
            load_average: get_load_average
          }
        when :linux
          cpu_info = File.read('/proc/cpuinfo') rescue ''
          model = cpu_info[/model name\s*:\s*(.+)/, 1] || 'unknown'
          cores = cpu_info.scan(/^processor/i).count
          {
            model: model,
            cores: cores,
            architecture: `uname -m 2>/dev/null`.strip,
            load_average: get_load_average
          }
        when :windows
          {
            model: `wmic cpu get name 2>nul`.lines[1]&.strip || 'unknown',
            cores: ENV['NUMBER_OF_PROCESSORS']&.to_i || 0,
            architecture: ENV['PROCESSOR_ARCHITECTURE'] || 'unknown'
          }
        else
          { cores: 0, model: 'unknown' }
        end
      end

      def get_memory_info
        case platform
        when :macos
          total_bytes = `sysctl -n hw.memsize 2>/dev/null`.strip.to_i
          # Get page size and memory statistics
          vm_stat = `vm_stat 2>/dev/null`
          page_size = vm_stat[/page size of (\d+)/, 1]&.to_i || 4096
          pages_free = vm_stat[/Pages free:\s+(\d+)/, 1]&.to_i || 0
          pages_inactive = vm_stat[/Pages inactive:\s+(\d+)/, 1]&.to_i || 0

          available_bytes = (pages_free + pages_inactive) * page_size
          used_bytes = total_bytes - available_bytes

          {
            total: format_bytes(total_bytes),
            total_bytes: total_bytes,
            available: format_bytes(available_bytes),
            available_bytes: available_bytes,
            used: format_bytes(used_bytes),
            used_bytes: used_bytes,
            percent_used: ((used_bytes.to_f / total_bytes) * 100).round(1)
          }
        when :linux
          meminfo = File.read('/proc/meminfo') rescue ''
          total_kb = meminfo[/MemTotal:\s+(\d+)/, 1]&.to_i || 0
          available_kb = meminfo[/MemAvailable:\s+(\d+)/, 1]&.to_i || 0
          used_kb = total_kb - available_kb

          {
            total: format_bytes(total_kb * 1024),
            total_bytes: total_kb * 1024,
            available: format_bytes(available_kb * 1024),
            available_bytes: available_kb * 1024,
            used: format_bytes(used_kb * 1024),
            used_bytes: used_kb * 1024,
            percent_used: total_kb > 0 ? ((used_kb.to_f / total_kb) * 100).round(1) : 0
          }
        when :windows
          # Using powershell for more reliable output
          output = `powershell -command "Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize,FreePhysicalMemory" 2>nul`
          total_kb = output[/TotalVisibleMemorySize\s*:\s*(\d+)/, 1]&.to_i || 0
          free_kb = output[/FreePhysicalMemory\s*:\s*(\d+)/, 1]&.to_i || 0
          used_kb = total_kb - free_kb

          {
            total: format_bytes(total_kb * 1024),
            total_bytes: total_kb * 1024,
            available: format_bytes(free_kb * 1024),
            available_bytes: free_kb * 1024,
            used: format_bytes(used_kb * 1024),
            used_bytes: used_kb * 1024,
            percent_used: total_kb > 0 ? ((used_kb.to_f / total_kb) * 100).round(1) : 0
          }
        else
          { total: 'unknown', available: 'unknown' }
        end
      end

      def get_disk_info
        disks = []

        case platform
        when :macos, :linux
          df_output = `df -h 2>/dev/null`.lines[1..]
          df_output&.each do |line|
            parts = line.split
            next if parts.length < 6
            next unless parts[0].start_with?('/') || parts[5]&.start_with?('/')

            mount_point = parts[5] || parts[0]
            disks << {
              filesystem: parts[0],
              size: parts[1],
              used: parts[2],
              available: parts[3],
              percent_used: parts[4],
              mount_point: mount_point
            }
          end
        when :windows
          output = `wmic logicaldisk get size,freespace,caption 2>nul`
          output.lines[1..].each do |line|
            parts = line.split
            next if parts.length < 3

            caption, free_space, size = parts
            next unless size.to_i > 0

            disks << {
              filesystem: caption,
              size: format_bytes(size.to_i),
              available: format_bytes(free_space.to_i),
              used: format_bytes(size.to_i - free_space.to_i),
              percent_used: "#{((1 - free_space.to_f / size.to_i) * 100).round}%"
            }
          end
        end

        disks
      end

      def get_network_info
        interfaces = []

        case platform
        when :macos
          ifconfig = `ifconfig 2>/dev/null`
          current_interface = nil

          ifconfig.each_line do |line|
            if line =~ /^(\w+):/
              current_interface = { name: $1, addresses: [] }
              interfaces << current_interface
            elsif current_interface && line =~ /inet (\d+\.\d+\.\d+\.\d+)/
              current_interface[:addresses] << { type: 'IPv4', address: $1 }
            elsif current_interface && line =~ /inet6 ([a-f0-9:]+)/
              current_interface[:addresses] << { type: 'IPv6', address: $1 }
            end
          end
        when :linux
          # Try ip command first, fall back to ifconfig
          output = `ip addr 2>/dev/null`
          if output.empty?
            output = `ifconfig 2>/dev/null`
          end

          current_interface = nil
          output.each_line do |line|
            if line =~ /^\d+:\s+(\w+):/
              current_interface = { name: $1, addresses: [] }
              interfaces << current_interface
            elsif line =~ /^(\w+):/
              current_interface = { name: $1, addresses: [] }
              interfaces << current_interface
            elsif current_interface && line =~ /inet (\d+\.\d+\.\d+\.\d+)/
              current_interface[:addresses] << { type: 'IPv4', address: $1 }
            elsif current_interface && line =~ /inet6 ([a-f0-9:]+)/
              current_interface[:addresses] << { type: 'IPv6', address: $1 }
            end
          end
        when :windows
          output = `ipconfig 2>nul`
          current_interface = nil

          output.each_line do |line|
            if line =~ /adapter (.+):/i
              current_interface = { name: $1.strip, addresses: [] }
              interfaces << current_interface
            elsif current_interface && line =~ /IPv4.*:\s*(\d+\.\d+\.\d+\.\d+)/
              current_interface[:addresses] << { type: 'IPv4', address: $1 }
            elsif current_interface && line =~ /IPv6.*:\s*([a-f0-9:]+)/i
              current_interface[:addresses] << { type: 'IPv6', address: $1 }
            end
          end
        end

        # Filter out interfaces with no addresses
        interfaces.select { |i| !i[:addresses].empty? }
      end

      def get_ruby_info
        {
          version: RUBY_VERSION,
          platform: RUBY_PLATFORM,
          engine: RUBY_ENGINE,
          engine_version: RUBY_ENGINE_VERSION,
          patchlevel: RUBY_PATCHLEVEL
        }
      end

      def platform
        case RUBY_PLATFORM
        when /darwin/
          :macos
        when /linux/
          :linux
        when /mswin|mingw|cygwin/
          :windows
        else
          :unknown
        end
      end

      def format_bytes(bytes)
        return '0 B' if bytes.nil? || bytes == 0

        units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB']
        exp = (Math.log(bytes) / Math.log(1024)).to_i
        exp = units.length - 1 if exp >= units.length

        "#{(bytes.to_f / (1024**exp)).round(2)} #{units[exp]}"
      end

      def get_load_average
        case platform
        when :macos, :linux
          uptime_output = `uptime 2>/dev/null`
          if uptime_output =~ /load average[s]?:\s*([\d.]+),?\s*([\d.]+),?\s*([\d.]+)/
            { '1min' => $1.to_f, '5min' => $2.to_f, '15min' => $3.to_f }
          else
            {}
          end
        else
          {}
        end
      end

      def parse_uptime(uptime_str)
        # Extract uptime portion from the uptime command output
        if uptime_str =~ /up\s+(.+?),\s+\d+\s+user/
          $1.strip
        elsif uptime_str =~ /up\s+(.+)/
          $1.split(',').first.strip
        else
          uptime_str
        end
      end

      def get_linux_distro
        if File.exist?('/etc/os-release')
          content = File.read('/etc/os-release')
          content[/^NAME="?([^"\n]+)"?/, 1] || 'Linux'
        elsif File.exist?('/etc/lsb-release')
          content = File.read('/etc/lsb-release')
          content[/DISTRIB_ID=(.+)/, 1] || 'Linux'
        else
          'Linux'
        end
      end

      def get_linux_version
        if File.exist?('/etc/os-release')
          content = File.read('/etc/os-release')
          content[/^VERSION="?([^"\n]+)"?/, 1] || ''
        elsif File.exist?('/etc/lsb-release')
          content = File.read('/etc/lsb-release')
          content[/DISTRIB_RELEASE=(.+)/, 1] || ''
        else
          ''
        end
      end
    end
  end
end
