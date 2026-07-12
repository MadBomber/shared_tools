# frozen_string_literal: true

require_relative "../../shared_tools"
require_relative "../process_runner"
require_relative "../command_guard"

module SharedTools
  module Tools
    # Runs ONE allowlisted executable with arguments.
    #
    # Deliberately NOT a shell: there are no pipes, redirects, globs,
    # quoting, or variable expansion. The program goes in `command`; each
    # argument is a separate element of `args` and is passed verbatim as
    # argv. This is the safe primitive that the OS-command-injection class of
    # bug cannot touch, because no shell ever parses the input.
    #
    # Requires user authorization (see SharedTools.execute?) AND the
    # executable being on allowed_commands (empty by default — nothing is
    # allowed until the caller configures it).
    #
    # @example
    #   tool = SharedTools::Tools::BashTool.new(allowed_commands: ["ls", "cat"])
    #   tool.execute(command: "ls", args: ["-la"])
    class BashTool < ::RubyLLM::Tool
      DEFAULT_TIMEOUT = 30

      def self.name = 'bash'

      description "Run a single ALLOWLISTED executable with arguments. " \
                  "No shell is involved: no pipes, redirects, globs, or variable expansion. " \
                  "Put the program name in `command` and each argument as its own element of `args`."

      params do
        string :command, description: "Executable name (must be on the allowlist). No path, no shell characters."
        array  :args,    of: :string, description: "Arguments passed verbatim to the program, one per element. Optional.", required: false
      end

      # @param allowed_commands [Array<String>] executables permitted to run. Empty by default (nothing allowed).
      # @param logger [Logger] optional logger
      def initialize(allowed_commands: [], logger: nil)
        @allowed_commands = allowed_commands
        @logger = logger || RubyLLM.logger
      end

      # @param command [String]
      # @param args [Array<String>, nil]
      #
      # @return [String, Hash]
      def execute(command:, args: nil)
        @logger.info("#{self.class.name}#execute command=#{command.inspect} args=#{args.inspect}")

        exe = SharedTools::CommandGuard.new(@allowed_commands).check!(command)
        argv = sanitize_args(args)

        allowed = SharedTools.execute?(tool: self.class.to_s, stuff: ([exe] + argv).join(" "))
        unless allowed
          @logger.warn("User declined to run #{([exe] + argv).join(' ')}")
          return { error: "User declined to run the command" }
        end

        out, err, status = SharedTools::ProcessRunner.capture(
          [exe, *argv],
          env: clean_env,
          timeout: DEFAULT_TIMEOUT,
          unsetenv_others: true
        )
        format_result(exe, argv, out, err, status)
      rescue SharedTools::CommandGuard::Blocked => e
        @logger.error("#{self.class.name} command denied: #{e.message}")
        { error: e.message }
      end

      private

      def sanitize_args(args)
        nul = 0.chr
        Array(args).map do |arg|
          str = arg.to_s
          raise SharedTools::CommandGuard::Blocked, "argument contains a NUL byte" if str.include?(nul)

          str
        end
      end

      def clean_env
        {}
      end

      def format_result(exe, argv, out, err, status)
        body = +"argv: #{([exe] + argv).inspect}\n"
        body << if status == :timeout
                  "result: timed out after #{DEFAULT_TIMEOUT}s (killed)\n"
                else
                  "exit: #{status.exitstatus}\n"
                end
        body << "\n--- stdout ---\n#{out}" unless out.empty?
        body << "\n--- stderr ---\n#{err}" unless err.empty?
        body
      end
    end
  end
end
