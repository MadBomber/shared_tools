#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: DocTool
#
# Shows how an LLM uses the DocTool to read and reason over document
# content. This demo uses the text_read action on a synthesised reference
# document (written to a temp file) to demonstrate Q&A and summarisation.
#
# For PDF support install: gem install pdf-reader
#
# Run:
#   bundle exec ruby -I examples examples/doc_tool_demo.rb

require_relative 'common'
require 'shared_tools/doc_tool'


require 'tmpdir'
require 'fileutils'

title "DocTool Demo"

work_dir = Dir.mktmpdir('doc_tool_demo_')
doc_path = File.join(work_dir, 'ruby_style_guide.txt')

File.write(doc_path, <<~DOCUMENT)
  Ruby Style Guide — Quick Reference
  ====================================

  1. NAMING CONVENTIONS
     - Classes and modules: CamelCase        (e.g. MyClass, HttpClient)
     - Methods and variables: snake_case      (e.g. my_method, user_name)
     - Constants: SCREAMING_SNAKE_CASE        (e.g. MAX_RETRIES, BASE_URL)
     - Predicates should end with ?           (e.g. valid?, empty?)
     - Dangerous methods should end with !    (e.g. save!, destroy!)

  2. INDENTATION & FORMATTING
     - Use 2 spaces per indentation level (never tabs)
     - Maximum line length: 120 characters
     - One blank line between method definitions
     - Two blank lines between class definitions

  3. STRINGS
     - Prefer single quotes unless interpolation is needed
     - Use double quotes when the string contains escape sequences
     - Use heredocs (<<~TEXT) for multi-line strings
     - Freeze string literals: # frozen_string_literal: true

  4. CONDITIONALS
     - Prefer guard clauses over deeply nested if/else
     - Use unless for simple negations (avoid unless ... else)
     - Use ternary operator only for trivial expressions
     - One-line if/unless for single-line bodies

  5. METHODS
     - Keep methods short — ideally under 10 lines
     - Use keyword arguments for methods with more than 2 parameters
     - Return early rather than wrapping code in an if block
     - Avoid using return in the last line (implicit return)

  6. BLOCKS & COLLECTIONS
     - Use { } for single-line blocks, do...end for multi-line
     - Prefer map/select/reject over manual array building
     - Use each_with_object or inject for complex accumulations
     - Avoid mutation where functional alternatives exist

  7. CLASSES
     - Use attr_accessor, attr_reader, attr_writer appropriately
     - Keep initialize simple — extract complex setup to private methods
     - Order: class methods, initialize, public, protected, private
     - Prefer composition over inheritance where practical

  8. ERROR HANDLING
     - Rescue StandardError, not Exception
     - Be specific about what you rescue
     - Always log or re-raise in rescue blocks
     - Avoid rescuing in a loop — rescue once at the boundary

  9. TESTING
     - Name tests clearly: describes what and under what condition
     - One assertion per test where possible
     - Use factories over fixtures for test data
     - Test behaviour, not implementation details

  10. TOOLS
      - Run RuboCop before every commit
      - Use Bundler for dependency management
      - Keep the Gemfile.lock in version control
      - Use semantic versioning for gem releases
DOCUMENT

@chat = @chat.with_tool(SharedTools::Tools::DocTool.new)

begin
  title "Read & Summarise", char: '-'
  ask "Read the document at '#{doc_path}' and give me a one-paragraph summary."

  title "Naming Rules", char: '-'
  ask "Read '#{doc_path}'. What naming convention should I use for constants? Give three examples."

  title "Method Guidelines", char: '-'
  ask "From '#{doc_path}', what are the recommendations for writing methods? List each point."

  title "Error Handling", char: '-'
  ask "Summarise the error handling section of '#{doc_path}' in plain English."

  title "Quick Reference Card", char: '-'
  ask <<~PROMPT
    Read '#{doc_path}' and produce a cheat-sheet with one key rule from each of
    the 10 sections. Format it as a numbered list.
  PROMPT

ensure
  FileUtils.rm_rf(work_dir)
  puts "\nTemporary document removed."
end

title "Done", char: '-'
puts "DocTool let the LLM read, comprehend, and answer questions about a text document."
