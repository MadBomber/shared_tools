# frozen_string_literal: true

# TODO: still trying to figure out how to properly handle functions in raix

require 'debug_me'
include DebugMe

require 'raix'
require 'shared_tools/raix/what_is_the_weather'

__END__


class MeaningOfLife
  include Raix::ChatCompletion
end

ai = MeaningOfLife.new
ai.transcript << { user: "What is the meaning of life?" }
r = ai.chat_completion

debug_me{[
  :r
]}

__END__
"The question of the meaning of life is one of the most profound and enduring inquiries in philosophy, religion, and science.
    Different perspectives offer various answers..."
