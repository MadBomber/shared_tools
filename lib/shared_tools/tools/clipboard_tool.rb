# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools
  module Tools
    # Read, write, and clear the system clipboard.
    # Supports macOS (pbcopy/pbpaste), Linux (xclip or xsel), and Windows (clip/PowerShell).
    #
    # @example
    #   tool = SharedTools::Tools::ClipboardTool.new
    #   tool.execute(action: 'write', text: 'Hello!')
    #   tool.execute(action: 'read')
    #   tool.execute(action: 'clear')
    class ClipboardTool < ::RubyLLM::Tool
      def self.name = 'clipboard_tool'

      description <<~DESC
        Read from, write to, and clear the system clipboard.
        Supports macOS, Linux (requires xclip or xsel), and Windows.

        Actions:
        - 'read'  — Return the current clipboard contents
        - 'write' — Replace clipboard contents with the given text
        - 'clear' — Empty the clipboard
      DESC

      params do
        string :action, description: "Action to perform: 'read', 'write', or 'clear'"
        string :text, required: false, description: "Text to write. Required only for the 'write' action."
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param action [String] 'read', 'write', or 'clear'
      # @param text   [String, nil] text for write action
      # @return [Hash] result
      def execute(action:, text: nil)
        @logger.info("ClipboardTool#execute action=#{action}")

        case action.to_s.downcase
        when 'read'  then read_clipboard
        when 'write' then write_clipboard(text)
        when 'clear' then clear_clipboard
        else
          { success: false, error: "Unknown action '#{action}'. Use: read, write, clear" }
        end
      rescue => e
        @logger.error("ClipboardTool error: #{e.message}")
        { success: false, error: e.message }
      end

      private

      def read_clipboard
        content = clipboard_read
        { success: true, content: content, length: content.length }
      end

      def write_clipboard(text)
        raise ArgumentError, "text is required for the write action" if text.nil?
        clipboard_write(text)
        { success: true, message: "Text written to clipboard", length: text.length }
      end

      def clear_clipboard
        clipboard_write('')
        { success: true, message: "Clipboard cleared" }
      end

      def clipboard_read
        if macos?
          `pbpaste`
        elsif linux_xclip?
          `xclip -selection clipboard -o 2>/dev/null`
        elsif linux_xsel?
          `xsel --clipboard --output 2>/dev/null`
        elsif windows?
          `powershell -command "Get-Clipboard" 2>/dev/null`.strip
        else
          raise "Clipboard not supported on this platform. Install xclip or xsel on Linux."
        end
      end

      def clipboard_write(text)
        if macos?
          IO.popen('pbcopy', 'w') { |io| io.write(text) }
        elsif linux_xclip?
          IO.popen('xclip -selection clipboard', 'w') { |io| io.write(text) }
        elsif linux_xsel?
          IO.popen('xsel --clipboard --input', 'w') { |io| io.write(text) }
        elsif windows?
          IO.popen('clip', 'w') { |io| io.write(text) }
        else
          raise "Clipboard not supported on this platform. Install xclip or xsel on Linux."
        end
      end

      def macos?
        RUBY_PLATFORM.include?('darwin')
      end

      def windows?
        RUBY_PLATFORM.match?(/mswin|mingw|cygwin/)
      end

      def linux_xclip?
        @linux_xclip ||= system('which xclip > /dev/null 2>&1')
      end

      def linux_xsel?
        @linux_xsel ||= system('which xsel > /dev/null 2>&1')
      end
    end
  end
end
