# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools
  module Tools
    # A tool for evaluating code in different programming languages
    class EvalTool < ::RubyLLM::Tool
      def self.name = 'eval_tool'

      module Action
        RUBY = "ruby"
        PYTHON = "python"
        SHELL = "shell"
      end

      ACTIONS = [
        Action::RUBY,
        Action::PYTHON,
        Action::SHELL,
      ].freeze

      description <<~TEXT
        Execute code in various programming languages (Ruby, Python, Shell).

        **WARNING**: This tool executes arbitrary code. All code execution requires user authorization for security.

        ## Actions:

        1. `#{Action::RUBY}` - Execute Ruby code
          Required: "action": "ruby", "code": "[Ruby code to execute]"

        2. `#{Action::PYTHON}` - Execute Python code
          Required: "action": "python", "code": "[Python code to execute]"
          Note: Requires python3 in system PATH

        3. `#{Action::SHELL}` - Execute shell commands
          Required: "action": "shell", "command": "[Shell command to execute]"

        ## Examples:

        Execute Ruby code
          {"action": "#{Action::RUBY}", "code": "puts 'Hello from Ruby'; 2 + 2"}

        Execute Python code
          {"action": "#{Action::PYTHON}", "code": "print('Hello from Python')\\nresult = 5 * 5\\nprint(result)"}

        Execute shell command
          {"action": "#{Action::SHELL}", "command": "ls -la"}

        Calculate with Ruby
          {"action": "#{Action::RUBY}", "code": "[1, 2, 3, 4, 5].sum"}

        Data processing with Python
          {"action": "#{Action::PYTHON}", "code": "import json\\ndata = {'name': 'test', 'value': 42}\\nprint(json.dumps(data))"}

        System info with shell
          {"action": "#{Action::SHELL}", "command": "uname -a"}
      TEXT

      params do
        string :action, description: <<~TEXT.strip
          The evaluation action to perform. Options:
          * `#{Action::RUBY}`: Execute Ruby code
          * `#{Action::PYTHON}`: Execute Python code (requires python3)
          * `#{Action::SHELL}`: Execute shell commands
        TEXT

        string :code, description: <<~TEXT.strip, required: false
          The code to execute. Required for the following actions:
          * `#{Action::RUBY}`
          * `#{Action::PYTHON}`
        TEXT

        string :command, description: <<~TEXT.strip, required: false
          The shell command to execute. Required for the following actions:
          * `#{Action::SHELL}`
        TEXT
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param action [String] the action to perform
      # @param code [String, nil] code to execute (for ruby/python)
      # @param command [String, nil] shell command to execute
      #
      # @return [Hash, String] execution result
      def execute(action:, code: nil, command: nil)
        @logger.info("EvalTool#execute action=#{action}")

        case action.to_s.downcase
        when Action::RUBY
          require_param!(:code, code)
          ruby_eval_tool.execute(code: code)
        when Action::PYTHON
          require_param!(:code, code)
          python_eval_tool.execute(code: code)
        when Action::SHELL
          require_param!(:command, command)
          shell_eval_tool.execute(command: command)
        else
          { error: "Unsupported action: #{action}. Supported actions are: #{ACTIONS.join(', ')}" }
        end
      rescue StandardError => e
        @logger.error("EvalTool execution failed: #{e.message}")
        { error: e.message }
      end

    private

      # @param name [Symbol]
      # @param value [Object]
      #
      # @raise [ArgumentError]
      # @return [void]
      def require_param!(name, value)
        raise ArgumentError, "#{name} param is required for this action" if value.nil?
      end

      # @return [Eval::RubyEvalTool]
      def ruby_eval_tool
        @ruby_eval_tool ||= Eval::RubyEvalTool.new(logger: @logger)
      end

      # @return [Eval::PythonEvalTool]
      def python_eval_tool
        @python_eval_tool ||= Eval::PythonEvalTool.new(logger: @logger)
      end

      # @return [Eval::ShellEvalTool]
      def shell_eval_tool
        @shell_eval_tool ||= Eval::ShellEvalTool.new(logger: @logger)
      end
    end
  end
end
