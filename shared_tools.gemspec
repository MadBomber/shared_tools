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

  # Core runtime dependencies
  spec.add_dependency "ruby_llm"
  spec.add_dependency "ruby_llm-mcp"
  spec.add_dependency "zeitwerk"
  spec.add_dependency "nokogiri"

  # Ruby 4.x ships bigdecimal-4.x as a default gem. Pin it explicitly so that
  # transitive deps (e.g. dentaku) cannot re-activate an older installed 3.x
  # version after 4.x is already active, which raises Gem::LoadError.
  if RUBY_VERSION >= "4.0"
    spec.add_dependency "bigdecimal", ">= 4.0"
  end

  # Optional tool dependencies - install separately if you need these tools.
  # Each tool guards its require with begin/rescue LoadError so that a missing
  # gem makes the individual tool unavailable rather than crashing all of shared_tools.
  spec.add_development_dependency "dentaku"          # For CalculatorTool
  spec.add_development_dependency "sequel"           # For DatabaseQueryTool
  spec.add_development_dependency "openweathermap"   # For WeatherTool
  spec.add_development_dependency "pdf-reader"       # For Doc::PdfReaderTool
  spec.add_development_dependency "docx"            # For Doc::DocxReaderTool
  spec.add_development_dependency "roo"             # For Doc::SpreadsheetReaderTool
  spec.add_development_dependency "sqlite3"          # For Database tools
  spec.add_development_dependency "ferrum"           # For Browser tools
  spec.add_development_dependency "macos"            # For Computer tools (macOS only)

  # For SharedTools development
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "debug_me"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-mock"   # stub/mock support (removed from minitest 6 core)
  spec.add_development_dependency "rake"
end
