# frozen_string_literal: true

require_relative "../../shared_tools"

module SharedTools
  verify_gem :raix

  class WhatIsTheWeather
    include ::Raix::ChatCompletion
    include ::Raix::FunctionDispatch

    function :check_weather,
             "Check the weather for a location",
             location: { type: "string", required: true } do |arguments|
      "The weather in #{arguments[:location]} is hot and sunny"
    end
  end
end
