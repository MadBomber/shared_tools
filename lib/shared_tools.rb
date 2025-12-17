# frozen_string_literal: true

require 'ruby_llm'
require 'io/console'

require "zeitwerk"

# Set up Zeitwerk loader outside module, then pass reference in
SharedToolsLoader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
SharedToolsLoader.ignore("#{__dir__}/shared_tools/ruby_llm.rb")
SharedToolsLoader.ignore("#{__dir__}/shared_tools/mcp.rb")       # Documentation/loader file only
SharedToolsLoader.ignore("#{__dir__}/shared_tools/mcp")          # Entire mcp directory (naming issues)
SharedToolsLoader.ignore("#{__dir__}/shared_tools/tools/browser.rb")
SharedToolsLoader.ignore("#{__dir__}/shared_tools/tools/computer.rb")
SharedToolsLoader.ignore("#{__dir__}/shared_tools/tools/database.rb")
SharedToolsLoader.ignore("#{__dir__}/shared_tools/tools/disk.rb")
SharedToolsLoader.ignore("#{__dir__}/shared_tools/tools/doc.rb")
SharedToolsLoader.ignore("#{__dir__}/shared_tools/tools/docker.rb")
SharedToolsLoader.ignore("#{__dir__}/shared_tools/tools/eval.rb")
SharedToolsLoader.ignore("#{__dir__}/shared_tools/tools/version.rb")  # Defines VERSION constant, not Version class
SharedToolsLoader.ignore("#{__dir__}/shared_tools/tools/incomplete")  # Empty/incomplete tools directory
SharedToolsLoader.setup

module SharedTools
  @auto_execute ||= true # Auto-execute by default, no human-in-the-loop

  class << self
    def auto_execute(wildwest=true)
      @auto_execute = wildwest
    end

    # Load all tool classes so they're available via ObjectSpace
    # Call this when using AIA with --rq shared_tools
    # Uses manual loading to gracefully handle missing dependencies
    def load_all_tools
      tools_dir = File.join(__dir__, 'shared_tools', 'tools')
      Dir.glob(File.join(tools_dir, '*_tool.rb')).each do |tool_file|
        begin
          require tool_file
        rescue LoadError => e
          # Skip tools with missing dependencies
          warn "SharedTools: Skipping #{File.basename(tool_file)} - #{e.message}" if ENV['DEBUG']
        end
      end
    end

    # Get all available tool classes (those that inherit from RubyLLM::Tool)
    # Only returns tools that can be successfully instantiated without arguments (RubyLLM requirement)
    def tools
      load_all_tools
      ObjectSpace.each_object(Class).select do |klass|
        next false unless klass < RubyLLM::Tool
        next false unless klass.to_s.start_with?('SharedTools::')

        # Actually try to instantiate the tool to verify it works
        # RubyLLM calls tool.new without args, so tools must be instantiable this way
        begin
          klass.new
          true
        rescue ArgumentError, LoadError, StandardError => e
          # Skip tools that can't be instantiated (missing args, missing platform drivers, etc.)
          warn "SharedTools: Excluding #{klass} - #{e.message}" if ENV['DEBUG']
          false
        end
      end
    end

    def execute?(tool: 'unknown', stuff: '')
      # Return true if auto_execute is explicitly enabled
      return true if @auto_execute == true

      puts "\n\nThe AI (tool: #{tool}) wants to do the following ..."
      puts "="*42
      puts(stuff.empty? ? "unknown strange and mysterious things" : stuff)
      puts "="*42

      sleep 0.2 if defined?(AIA) # Allows CLI spinner to recycle
      print "\nIs it okay to proceed? (y/N"
      STDIN.getch == "y"
    end
  end
end
