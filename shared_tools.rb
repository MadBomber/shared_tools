# frozen_string_literal: true
# shared_tools.rb
#
# SharedTools module provides common functionality accessible across the application.
# It includes a configurable logger that is automatically available to all classes
# within the SharedTools namespace without requiring explicit includes.

require "logger"
require "singleton"

module SharedTools
  # Default log level if not specified
  DEFAULT_LOG_LEVEL = Logger::INFO

  # Hook method called whenever this module is included in another module/class
  def self.included(base)
    # Add class methods automatically
    base.extend(ClassMethods)

    # Handle the case where we're including in a class
    if base.is_a?(Class)
      base.class_eval do
        include InstanceMethods
      end
    else
      # For modules, propagate the automatic inclusion to their classes
      base.module_eval do
        def self.included(sub_base)
          sub_base.include(SharedTools)
        end
      end
    end
  end

  # Hook method when module is extending an object
  def self.extended(object)
    object.extend(ClassMethods)
  end

  # Methods to be added to all SharedTools classes
  module InstanceMethods
    # Access the shared logger instance
    # @return [Logger] The shared logger instance
    def logger
      SharedTools.logger
    end
  end

  # Class methods to be added to all SharedTools classes
  module ClassMethods
    # Access the shared logger from class context
    # @return [Logger] The shared logger instance
    def logger
      SharedTools.logger
    end
  end

  # LoggerConfiguration handles the setup and configuration of the shared logger
  class LoggerConfiguration
    include Singleton

    attr_accessor :level, :log_device, :formatter

    def initialize
      @level = DEFAULT_LOG_LEVEL
      @log_device = STDOUT
      @formatter = nil
    end

    # Apply current configuration to a logger instance
    def apply_to(logger)
      logger.level = @level
      logger.formatter = @formatter if @formatter
    end
  end

  # Module methods for SharedTools
  class << self
    # Returns the shared logger instance
    # @return [Logger] The configured logger instance
    def logger
      @logger ||= create_logger
    end

    # Sets a custom logger instance
    # @param new_logger [Logger] A Logger instance to use
    def logger=(new_logger)
      @logger = new_logger
    end

    # Configure the logger through a block
    # @example
    #   SharedTools.configure_logger do |config|
    #     config.level = Logger::DEBUG
    #     config.log_device = 'logs/application.log'
    #     config.formatter = proc { |severity, time, progname, msg| "[#{time}] #{severity} - #{msg}\n" }
    #   end
    def configure_logger
      yield LoggerConfiguration.instance

      # If logger already exists, apply new configuration
      if @logger
        @logger = create_logger
      end
    end

    private

    # Creates a new logger with the current configuration
    # @return [Logger] A newly configured logger
    def create_logger
      config = LoggerConfiguration.instance
      logger = Logger.new(config.log_device)
      config.apply_to(logger)
      logger
    end
  end
end
