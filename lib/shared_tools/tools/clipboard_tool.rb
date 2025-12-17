# frozen_string_literal: true

require 'ruby_llm/tool'

module SharedTools
  module Tools
    # A tool for reading from and writing to the system clipboard.
    # Supports macOS (pbcopy/pbpaste), Linux (xclip/xsel), and Windows (clip).
    #
    # @example
    #   tool = SharedTools::Tools::ClipboardTool.new
    #   tool.execute(action: 'write', content: 'Hello, World!')
    #   result = tool.execute(action: 'read')
    #   puts result[:content]  # "Hello, World!"
    class ClipboardTool < RubyLLM::Tool
      def self.name = 'clipboard'

      description <<~'DESCRIPTION'
        Read from or write to the system clipboard.

        This tool provides cross-platform clipboard access:
        - macOS: Uses pbcopy/pbpaste
        - Linux: Uses xclip or xsel (must be installed)
        - Windows: Uses clip/powershell

        Actions:
        - 'read': Get the current clipboard contents
        - 'write': Set the clipboard contents
        - 'clear': Clear the clipboard

        Example usage:
          tool = SharedTools::Tools::ClipboardTool.new

          # Write to clipboard
          tool.execute(action: 'write', content: 'Hello, World!')

          # Read from clipboard
          result = tool.execute(action: 'read')
          puts result[:content]

          # Clear clipboard
          tool.execute(action: 'clear')
      DESCRIPTION

      params do
        string :action, description: <<~DESC.strip
          The clipboard action to perform:
          - 'read': Get current clipboard contents
          - 'write': Set clipboard contents (requires 'content' parameter)
          - 'clear': Clear the clipboard
        DESC

        string :content, description: <<~DESC.strip, required: false
          The text content to write to the clipboard.
          Required when action is 'write'.
        DESC
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # Execute clipboard action
      #
      # @param action [String] 'read', 'write', or 'clear'
      # @param content [String, nil] content to write (required for 'write' action)
      # @return [Hash] result with success status and content/error
      def execute(action:, content: nil)
        @logger.info("ClipboardTool#execute action=#{action.inspect}")

        case action.to_s.downcase
        when 'read'
          read_clipboard
        when 'write'
          write_clipboard(content)
        when 'clear'
          clear_clipboard
        else
          {
            success: false,
            error: "Unknown action: #{action}. Valid actions are: read, write, clear"
          }
        end
      rescue => e
        @logger.error("ClipboardTool error: #{e.message}")
        {
          success: false,
          error: e.message
        }
      end

      private

      def read_clipboard
        content = case platform
                  when :macos
                    `pbpaste 2>/dev/null`
                  when :linux
                    if command_exists?('xclip')
                      `xclip -selection clipboard -o 2>/dev/null`
                    elsif command_exists?('xsel')
                      `xsel --clipboard --output 2>/dev/null`
                    else
                      raise "No clipboard tool found. Install xclip or xsel."
                    end
                  when :windows
                    `powershell -command "Get-Clipboard" 2>nul`.chomp
                  else
                    raise "Unsupported platform: #{RUBY_PLATFORM}"
                  end

        {
          success: true,
          content: content,
          length: content.length
        }
      end

      def write_clipboard(content)
        if content.nil? || content.empty?
          return {
            success: false,
            error: "Content is required for write action"
          }
        end

        case platform
        when :macos
          IO.popen('pbcopy', 'w') { |io| io.print content }
        when :linux
          if command_exists?('xclip')
            IO.popen('xclip -selection clipboard', 'w') { |io| io.print content }
          elsif command_exists?('xsel')
            IO.popen('xsel --clipboard --input', 'w') { |io| io.print content }
          else
            raise "No clipboard tool found. Install xclip or xsel."
          end
        when :windows
          IO.popen('clip', 'w') { |io| io.print content }
        else
          raise "Unsupported platform: #{RUBY_PLATFORM}"
        end

        {
          success: true,
          message: "Content written to clipboard",
          length: content.length
        }
      end

      def clear_clipboard
        case platform
        when :macos
          IO.popen('pbcopy', 'w') { |io| io.print '' }
        when :linux
          if command_exists?('xclip')
            IO.popen('xclip -selection clipboard', 'w') { |io| io.print '' }
          elsif command_exists?('xsel')
            IO.popen('xsel --clipboard --input', 'w') { |io| io.print '' }
          else
            raise "No clipboard tool found. Install xclip or xsel."
          end
        when :windows
          IO.popen('clip', 'w') { |io| io.print '' }
        else
          raise "Unsupported platform: #{RUBY_PLATFORM}"
        end

        {
          success: true,
          message: "Clipboard cleared"
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

      def command_exists?(cmd)
        system("which #{cmd} > /dev/null 2>&1")
      end
    end
  end
end
