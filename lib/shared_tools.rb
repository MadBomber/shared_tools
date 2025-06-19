# frozen_string_literal: true

require 'io/console'

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
# Ignore aggregate loader files that don't define constants
loader.ignore("#{__dir__}/shared_tools/ruby_llm.rb")
loader.ignore("#{__dir__}/shared_tools/llm_rb.rb")
loader.ignore("#{__dir__}/shared_tools/omniai.rb")
loader.ignore("#{__dir__}/shared_tools/raix.rb")
loader.setup

module SharedTools
  SUPPORTED_GEMS = %i(ruby_llm llm_rb omniai raix)
  @auto_execute = false # Human in the loop

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


    def detected_gem
      return :ruby_llm  if defined?(::RubyLLM::Tool)
      return :llm_rb    if defined?(::LLM) || defined?(::Llm)
      return :omniai    if defined?(::OmniAI) || defined?(::Omniai)
      return :raix      if defined?(::Raix::FunctionDispatch)
      nil
    end

    def verify_gem(a_symbol)
      loaded = a_symbol == detected_gem
      return true if loaded
      raise "SharedTools: Please require '#{a_symbol}' gem before requiring 'shared_tools'."
    end
  end

  if detected_gem.nil?
    warn "⚠️  SharedTools: No supported gem detected. Supported gems are: #{SUPPORTED_GEMS.join(', ')}"
  end
end
