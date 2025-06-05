# frozen_string_literal: true

require_relative "lib/shared_tools/version"

Gem::Specification.new do |spec|
  spec.name          = "shared_tools"
  spec.version       = SharedTools::VERSION
  spec.authors       = ["MadBomber Team"]
  spec.email         = ["example@example.com"]

  spec.summary       = "A collection of shared tools and utilities for Ruby applications"
  spec.description   = "SharedTools provides common functionality including configurable logging and LLM tools"
  spec.homepage      = "https://github.com/madbomber/shared_tools"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
    lib/**/*.rb
    LICENSE
    README.md
    CHANGELOG.md
  ])
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "logger", "~> 1.0"
  spec.add_dependency "pdf-reader", "~> 2.0"
  
  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
