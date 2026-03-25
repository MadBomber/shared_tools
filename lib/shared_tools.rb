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

# Ignore per-tool shim files (require-path shortcuts: require 'shared_tools/<tool_name>')
Dir.glob("#{__dir__}/shared_tools/*_tool.rb").each { |f| SharedToolsLoader.ignore(f) }
SharedToolsLoader.ignore("#{__dir__}/shared_tools/data_science_kit.rb")
SharedToolsLoader.ignore("#{__dir__}/shared_tools/devops_toolkit.rb")

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
  end
end
