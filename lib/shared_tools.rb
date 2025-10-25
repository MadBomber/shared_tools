# frozen_string_literal: true

require 'ruby_llm'
require 'io/console'

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
# Ignore aggregate loader files that don't define constants
loader.ignore("#{__dir__}/shared_tools/ruby_llm.rb")
loader.ignore("#{__dir__}/shared_tools/tools/browser.rb")
loader.ignore("#{__dir__}/shared_tools/tools/computer.rb")
loader.ignore("#{__dir__}/shared_tools/tools/database.rb")
loader.ignore("#{__dir__}/shared_tools/tools/disk.rb")
loader.ignore("#{__dir__}/shared_tools/tools/doc.rb")
loader.ignore("#{__dir__}/shared_tools/tools/docker.rb")
loader.ignore("#{__dir__}/shared_tools/tools/eval.rb")
loader.setup

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
