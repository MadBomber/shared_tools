# frozen_string_literal: true

require "logger"
require "singleton"

module SharedTools
  DEFAULT_LOG_LEVEL = Logger::INFO

  module InstanceMethods
    # @return [Logger] The shared logger instance
    def logger
      SharedTools.logger
    end
  end

  module ClassMethods
    # @return [Logger] The shared logger instance
    def logger
      SharedTools.logger
    end
  end


  class LoggerConfiguration
    include Singleton

    attr_accessor :level, :log_device, :formatter

    def initialize
      @level = DEFAULT_LOG_LEVEL
      @log_device = STDOUT
      @formatter = nil
    end


    def apply_to(logger)
      logger.level = @level
      logger.formatter = @formatter if @formatter
    end
  end


  class << self
    # @return [Logger] The configured logger instance
    def logger
      @logger ||= create_logger
    end

    # @param new_logger [Logger] A Logger instance to use
    def logger=(new_logger)
      @logger = new_logger
    end


    # @example
    #   SharedTools.configure_logger do |config|
    #     config.level = Logger::DEBUG
    #     config.log_device = 'logs/application.log'
    #     config.formatter = proc { |severity, time, progname, msg| "[#{time}] #{severity} - #{msg}\n" }
    #   end
    def configure_logger
      yield LoggerConfiguration.instance


      if @logger
        @logger = create_logger
      end
    end

    private

    # @return [Logger] A newly configured logger
    def create_logger
      config = LoggerConfiguration.instance
      logger = Logger.new(config.log_device)
      config.apply_to(logger)
      logger
    end
  end


  # module LoggingSupport
  #   def self.included(base)
  #     base.include(SharedTools)
  #   end
  # end
end
