#!/usr/bin/env ruby
# frozen_string_literal: true

# TODO: still trying to figure out how to properly handle functions in raix

require "debug_me"
include DebugMe

require "raix"
require 'faraday/retry'

retry_options = {
  max: 2,
  interval: 0.05,
  interval_randomness: 0.5,
  backoff_factor: 2
}

require_relative "../lib/shared_tools/raix/what_is_the_weather"

OpenRouter.configure do |config|
  config.faraday do |f|
    f.request :retry, retry_options
    f.response :logger, Logger.new($stdout), { headers: true, bodies: true, errors: true } do |logger|
      logger.filter(/(Bearer) (\S+)/, '\1[REDACTED]')
    end
  end
end


Raix.configure do |config|
  # config.openrouter_client = OpenRouter::Client.new(access_token: ENV.fetch("OPENROUTER_API_KEY", nil))
  config.openai_client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY", nil)) do |f|
    f.request :retry, retry_options
    f.response :logger, Logger.new($stdout), { headers: true, bodies: true, errors: true } do |logger|
      logger.filter(/(Bearer) (\S+)/, '\1[REDACTED]')
    end
  end
end

class MeaningOfLife
  include Raix::ChatCompletion
end

ai = MeaningOfLife.new
ai.transcript << { user: "What is the meaning of life?" }
r = ai.chat_completion(openai: "gpt-4o-mini")

debug_me{[
  :r
]}


__END__
"The question of the meaning of life is one of the most profound and enduring inquiries in philosophy, religion, and science.
    Different perspectives offer various answers..."
