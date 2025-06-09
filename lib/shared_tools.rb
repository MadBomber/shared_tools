# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module SharedTools
  @st_supported_gems = [:ruby_llm, :llm_rb, :omniai]

  class << self
    def detected_gem
      return :ruby_llm  if defined?(::RubyLLM::Tool)
      return :llm_rb    if defined?(::LLM) || defined?(::Llm)
      return :omniai    if defined?(::OmniAI) || defined?(::Omniai)
      nil
    end

    def verify_gem(a_symbol)
      loaded = a_symbol == detected_gem
      return true if loaded
      raise "SharedTools: Please require '#{a_symbol}' gem before requiring 'shared_tools'."
    end
  end

  if detected_gem.nil?
    warn "⚠️  SharedTools: No supported LLM provider API gem detected. Please require one of: #{@st_supported_gems.join(', ')} before requiring shared_tools."
  end
end
