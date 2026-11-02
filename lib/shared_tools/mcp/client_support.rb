# frozen_string_literal: true

# lib/shared_tools/mcp/client_support.rb
#
# Class-level helpers shared by the SharedTools MCP server classes.
#
# Each client in this directory is a plain RubyLLM::MCP subclass (ruby_llm >= 2.1)
# that describes ONE server with the class-level DSL (command / env / url /
# bearer_token / timeout ...). Defining the class has no side effects: no process
# is started, nothing is downloaded and no network connection is made until a
# chat or robot first asks the server for its tools.
#
# This module adds a little SharedTools-specific metadata on top of that DSL:
#
#   class SharedTools::MCP::GitHub < RubyLLM::MCP
#     extend SharedTools::MCP::ClientSupport
#     requires_envars  "GITHUB_PERSONAL_ACCESS_TOKEN"
#     requires_packages "github-mcp-server"
#     command "github-mcp-server", "stdio"
#   end
#
#   SharedTools::MCP::GitHub.available?        #=> false when the token is unset
#   SharedTools::MCP::GitHub.missing_envars    #=> ["GITHUB_PERSONAL_ACCESS_TOKEN"]
#   SharedTools::MCP::GitHub.install_packages! # brew/apt/dnf install, on demand only

require "ruby_llm"
require_relative "../utilities"

module SharedTools
  module MCP
    @clients = []

    class << self
      # Every SharedTools MCP server class that has been loaded.
      def clients
        @clients.dup
      end

      # The loaded server classes whose required environment variables are set.
      #
      #   RobotLab.build(mcp: SharedTools::MCP.available)
      def available
        @clients.select(&:available?)
      end

      def register(klass) # :nodoc:
        @clients << klass unless @clients.include?(klass)
        klass
      end
    end

    module ClientSupport
      # Instance-side reader, so a server instance answers #description the
      # way robot_lab's RobotLab::MCP::Server does.
      module InstanceMethods
        def description
          self.class.description.to_s
        end
      end

      def self.extended(klass)
        klass.include(InstanceMethods)
        SharedTools::MCP.register(klass)
      end

      # Declares (or, with no argument, returns) a short description of what
      # the server offers. robot_lab's mcp_discovery scores servers by name
      # plus description, so a description lets it pick this server for
      # relevant messages. Subclasses inherit their parent's description.
      def description(text = nil)
        return @description || (superclass.description if superclass.respond_to?(:description)) if text.nil?

        @description = text.to_s
      end

      # Declares (or, with no arguments, returns) the environment variables
      # the server needs. All of them must be set for #available? to be true.
      def requires_envars(*names)
        return @required_envars || [] if names.empty?

        @required_envars = names.flatten.map(&:to_s)
      end

      # Declares (or returns) the OS packages that provide the server binary.
      # They are only installed when #install_packages! is called.
      def requires_packages(*names)
        return @required_packages || [] if names.empty?

        @required_packages = names.flatten.map(&:to_s)
      end

      def missing_envars
        requires_envars.select { |name| ENV.fetch(name, "").empty? }
      end

      def available?
        missing_envars.empty?
      end

      # Raises LoadError (like SharedTools.verify_envars) when a required
      # environment variable is missing; returns the class otherwise.
      def verify!
        missing = missing_envars
        raise LoadError, "Missing envars: #{missing.join(', ')}" unless missing.empty?

        self
      end

      # Installs the server's OS packages via SharedTools.package_install.
      def install_packages!
        SharedTools.package_install(*requires_packages) unless requires_packages.empty?
        self
      end

      # An environment variable read when the server process starts rather
      # than when the class is defined. Missing variables resolve to "".
      def env_from(name)
        -> { ENV.fetch(name, "") }
      end
    end
  end
end
