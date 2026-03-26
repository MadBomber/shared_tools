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
SharedToolsLoader.ignore("#{__dir__}/shared_tools/tools/notification.rb")
SharedToolsLoader.ignore("#{__dir__}/shared_tools/tools/version.rb")  # Defines VERSION constant, not Version class
SharedToolsLoader.ignore("#{__dir__}/shared_tools/tools/incomplete")  # Empty/incomplete tools directory
SharedToolsLoader.ignore("#{__dir__}/shared_tools/tools/enabler.rb") # Experimental; defines Tools::Enabler not SharedTools::Tools::Enabler

# Ignore per-tool shim files (require-path shortcuts: require 'shared_tools/<tool_name>')
Dir.glob("#{__dir__}/shared_tools/*_tool.rb").each { |f| SharedToolsLoader.ignore(f) }
SharedToolsLoader.ignore("#{__dir__}/shared_tools/data_science_kit.rb")
SharedToolsLoader.ignore("#{__dir__}/shared_tools/database.rb")
SharedToolsLoader.ignore("#{__dir__}/shared_tools/utilities.rb")  # Reopens SharedTools, not SharedTools::Utilities

SharedToolsLoader.setup

module SharedTools
  @auto_execute   ||= true # Auto-execute by default, no human-in-the-loop
  class << self

    def auto_execute(wildwest=true)
      @auto_execute = wildwest
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

    # Force-load all tool classes into ObjectSpace.
    # Called by AIA's GemActivator.trigger_tool_loading when shared_tools is
    # passed to --require. Without this, Zeitwerk lazy-loads classes on first
    # reference, so no RubyLLM::Tool subclasses appear in ObjectSpace at scan time.
    def load_all_tools
      SharedToolsLoader.eager_load
    end

    # Return all loaded RubyLLM::Tool subclasses provided by this gem.
    # Also triggers eager loading so the list is complete.
    def tools
      load_all_tools
      ObjectSpace.each_object(Class).select { |k| k < ::RubyLLM::Tool }.to_a
    end
  end
end

require_relative "shared_tools/utilities"
