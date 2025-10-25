# frozen_string_literal: true

require_relative "lib/shared_tools/version"

Gem::Specification.new do |spec|
  spec.name          = "shared_tools"
  spec.version       = SharedTools::VERSION
  spec.authors       = ["Dewayne VanHoozer"]
  spec.email         = ["dvanhoozer@gmail.com"]

  spec.summary       = "Shared utilities and AI tools for Ruby applications with configurable logging"
  spec.description   = <<~DESC
    SharedTools provides a collection of reusable common tools
    for Ruby applications using ruby_llm gem.
  DESC
  spec.homepage      = "https://github.com/madbomber/shared_tools"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"]     = spec.homepage
  spec.metadata["source_code_uri"]  = spec.homepage
  spec.metadata["changelog_uri"]    = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
    lib/**/*.rb
    LICENSE
    README.md
    CHANGELOG.md
  ])

  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "ruby_llm"
  spec.add_dependency "zeitwerk"
  spec.add_dependency "nokogiri"

  # Development dependencies

  # Support gems
  spec.add_development_dependency "pdf-reader", "~> 2.0"
  spec.add_development_dependency "ruby_llm-mcp", "~> 0.5.1"


  # For SharedTools development
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "debug_me"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "sqlite3"
end
