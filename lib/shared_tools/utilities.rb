# frozen_string_literal: true
#
# lib/shared_tools/utilities.rb
#
# General-purpose utility methods for SharedTools MCP clients and tools.
# Loaded automatically by lib/shared_tools.rb.

module SharedTools
  class << self

    # Returns true if all named environment variables are set and non-empty.
    # Warns for each missing variable and returns false if any are absent.
    #
    #   SharedTools.verify_envars("GITHUB_PERSONAL_ACCESS_TOKEN")
    #   SharedTools.verify_envars("TAVILY_API_KEY", "ANOTHER_KEY")
    def verify_envars(*names)
      missing = names.select { |n| ENV.fetch(n, "").empty? }
      missing.each { |n| warn "SharedTools — #{n} is not set" }
      unless missing.empty?
        raise LoadError, "Missing envars: #{missing.join(', ')}"
      end
    end

    # High-level package installer. Detects the current platform and calls the
    # appropriate *_install method. Raises LoadError if any package cannot be installed.
    #
    #   SharedTools.package_install("github-mcp-server")
    #   SharedTools.package_install("curl", "jq")
    def package_install(*packages)
      case RUBY_PLATFORM
      when /darwin/
        brew_install(*packages)
      when /linux/
        if system("which apt-get > /dev/null 2>&1")
          apt_install(*packages)
        elsif system("which dnf > /dev/null 2>&1")
          dnf_install(*packages)
        elsif system("which brew > /dev/null 2>&1")
          brew_install(*packages)
        else
          raise LoadError, "No supported package manager found (apt-get, dnf, brew)"
        end
      else
        raise LoadError, "Unsupported platform: #{RUBY_PLATFORM}"
      end
    end

    # Ensures each named binary is available in PATH, installing via brew if missing.
    # Raises LoadError if brew is not installed or any package install fails.
    #
    #   SharedTools.brew_install("github-mcp-server")
    #   SharedTools.brew_install("gh", "jq")
    def brew_install(*packages)
      raise LoadError, "Homebrew is not installed (https://brew.sh)" unless system("which brew > /dev/null 2>&1")

      packages.each do |pkg|
        next unless `brew list --versions #{pkg} 2>/dev/null`.strip.empty?

        warn "SharedTools — #{pkg} not found, installing via brew..."
        raise LoadError, "#{pkg} could not be installed" unless system("brew install --quiet #{pkg} > /dev/null 2>&1")
      end
    end

    # Ensures each named binary is available in PATH, installing via apt-get if missing.
    # Raises LoadError if any package install fails.
    #
    #   SharedTools.apt_install("curl")
    #   SharedTools.apt_install("curl", "jq")
    def apt_install(*packages)
      packages.each do |pkg|
        # SMELL: what if package is a library?
        next if system("which #{pkg} > /dev/null 2>&1")

        warn "SharedTools — #{pkg} not found, installing via apt-get..."
        raise LoadError, "#{pkg} could not be installed" unless system("sudo apt-get install -y -q #{pkg} > /dev/null 2>&1")
      end
    end

    # Ensures each named binary is available in PATH, installing via dnf if missing.
    # Raises LoadError if any package install fails.
    #
    #   SharedTools.dnf_install("curl")
    #   SharedTools.dnf_install("curl", "jq")
    def dnf_install(*packages)
      packages.each do |pkg|
        # SMELL: What if package is a library?
        next if system("which #{pkg} > /dev/null 2>&1")

        warn "SharedTools — #{pkg} not found, installing via dnf..."
        raise LoadError, "#{pkg} could not be installed" unless system("sudo dnf install -y -q #{pkg} > /dev/null 2>&1")
      end
    end

    # Ensures each named npm package binary is available in PATH, installing
    # globally via npm if missing. Raises LoadError if npm is not found or any install fails.
    #
    #   SharedTools.npm_install("typescript")
    #   SharedTools.npm_install("typescript", "ts-node")
    def npm_install(*packages)
      raise LoadError, "npm is not installed (https://nodejs.org)" unless system("which npm > /dev/null 2>&1")

      packages.each do |pkg|
        # SMELL: What if package is a library?
        next if system("which #{pkg} > /dev/null 2>&1")

        warn "SharedTools — #{pkg} not found, installing via npm..."
        raise LoadError, "#{pkg} could not be installed" unless system("npm install -g --silent #{pkg} > /dev/null 2>&1")
      end
    end

    # Ensures each named gem is available, installing via gem install if missing.
    # Raises LoadError if gem is not available or any install fails.
    #
    #   SharedTools.gem_install("nokogiri")
    #   SharedTools.gem_install("nokogiri", "oj")
    def gem_install(*packages)
      raise LoadError, "gem is not available" unless system("which gem > /dev/null 2>&1")

      packages.each do |pkg|
        next if system("gem list -i #{pkg} > /dev/null 2>&1")

        warn "SharedTools — #{pkg} not found, installing via gem..."
        raise LoadError, "#{pkg} could not be installed" unless system("gem install --silent #{pkg} > /dev/null 2>&1")
      end
    end

  end
end
