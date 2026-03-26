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
      missing.empty?
    end

    # High-level package installer. Detects the current platform and calls the
    # appropriate *_install method. Returns true if all packages are available.
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
          warn "SharedTools — no supported package manager found (apt-get, dnf, brew)"
          false
        end
      else
        warn "SharedTools — unsupported platform: #{RUBY_PLATFORM}"
        false
      end
    end

    # Ensures each named binary is available in PATH, installing via brew if missing.
    # Returns true if all binaries are present (or successfully installed).
    # Returns false if brew itself is missing or any install fails.
    #
    #   SharedTools.brew_install("github-mcp-server")
    #   SharedTools.brew_install("gh", "jq")
    def brew_install(*packages)
      unless system("which brew > /dev/null 2>&1")
        warn "SharedTools — Homebrew is not installed (https://brew.sh)"
        return false
      end

      packages.all? do |pkg|
        next true if !`brew list --versions #{pkg} 2>/dev/null`.strip.empty?

        warn "SharedTools — #{pkg} not found, installing via brew..."
        system("brew install --quiet #{pkg} > /dev/null 2>&1")
      end
    end

    # Ensures each named binary is available in PATH, installing via apt-get if missing.
    # Returns true if all binaries are present (or successfully installed).
    # Returns false if apt-get itself is missing or any install fails.
    #
    #   SharedTools.apt_install("curl")
    #   SharedTools.apt_install("curl", "jq")
    def apt_install(*packages)
      packages.all? do |pkg|
        # SMELL: what if package is a library?
        next true if system("which #{pkg} > /dev/null 2>&1")

        warn "SharedTools — #{pkg} not found, installing via apt-get..."
        system("sudo apt-get install -y -q #{pkg} > /dev/null 2>&1")
      end
    end

    # Ensures each named binary is available in PATH, installing via dnf if missing.
    # Returns true if all binaries are present (or successfully installed).
    # Returns false if dnf itself is missing or any install fails.
    #
    #   SharedTools.dnf_install("curl")
    #   SharedTools.dnf_install("curl", "jq")
    def dnf_install(*packages)
      packages.all? do |pkg|
        # SMELL: What if package is a library?
        next true if system("which #{pkg} > /dev/null 2>&1")

        warn "SharedTools — #{pkg} not found, installing via dnf..."
        system("sudo dnf install -y -q #{pkg} > /dev/null 2>&1")
      end
    end

    # Ensures each named npm package binary is available in PATH, installing
    # globally via npm if missing. Returns false if npm itself is not found.
    #
    #   SharedTools.npm_install("typescript")
    #   SharedTools.npm_install("typescript", "ts-node")
    def npm_install(*packages)
      unless system("which npm > /dev/null 2>&1")
        warn "SharedTools — npm is not installed (https://nodejs.org)"
        return false
      end

      packages.all? do |pkg|
        # SMELL: What if package is a library?
        next true if system("which #{pkg} > /dev/null 2>&1")

        warn "SharedTools — #{pkg} not found, installing via npm..."
        system("npm install -g --silent #{pkg} > /dev/null 2>&1")
      end
    end

    # Ensures each named gem is available, installing via gem install if missing.
    # Returns false if gem itself is not found (should never happen in a Ruby process).
    #
    #   SharedTools.gem_install("nokogiri")
    #   SharedTools.gem_install("nokogiri", "oj")
    def gem_install(*packages)
      unless system("which gem > /dev/null 2>&1")
        warn "SharedTools — gem is not available"
        return false
      end

      packages.all? do |pkg|
        next true if system("gem list -i #{pkg} > /dev/null 2>&1")

        warn "SharedTools — #{pkg} not found, installing via gem..."
        system("gem install --silent #{pkg} > /dev/null 2>&1")
      end
    end

  end
end
