#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using DocTool for document processing
#
# This example demonstrates how to use the DocTool facade to read and
# extract text from PDF documents.

require 'bundler/setup'
require 'shared_tools'
require 'fileutils'

puts "=" * 80
puts "DocTool Example - PDF Document Processing"
puts "=" * 80
puts

# Initialize the doc tool
doc_tool = SharedTools::Tools::DocTool.new

# Path to a sample PDF (using the test fixture)
sample_pdf = File.expand_path('../test/fixtures/test.pdf', __dir__)

unless File.exist?(sample_pdf)
  puts "ERROR: Sample PDF not found at #{sample_pdf}"
  puts "Please ensure a PDF file exists at that location to run this example."
  exit 1
end

puts "Using sample PDF: #{sample_pdf}"
puts "File size: #{(File.size(sample_pdf) / 1024.0 / 1024.0).round(2)} MB"
puts

begin
  # Example 1: Read a single page
  puts "1. Reading a Single Page"
  puts "-" * 40

  result = doc_tool.execute(
    action: SharedTools::Tools::DocTool::Action::PDF_READ,
    doc_path: sample_pdf,
    page_numbers: "1"
  )

  puts "Total pages in document: #{result[:total_pages]}"
  puts "Pages requested: #{result[:requested_pages].inspect}"
  puts "Pages extracted: #{result[:pages].size}"
  puts
  puts "First 200 characters of page 1:"
  puts result[:pages].first[:text][0..200] + "..."
  puts

  # Example 2: Read multiple specific pages
  puts "2. Reading Multiple Specific Pages"
  puts "-" * 40

  result = doc_tool.execute(
    action: SharedTools::Tools::DocTool::Action::PDF_READ,
    doc_path: sample_pdf,
    page_numbers: "1, 2, 3"
  )

  puts "Requested pages: 1, 2, 3"
  puts "Successfully extracted: #{result[:pages].size} pages"

  result[:pages].each do |page|
    text_length = page[:text]&.length || 0
    puts "  Page #{page[:page]}: #{text_length} characters"
  end
  puts

  # Example 3: Handling invalid page numbers
  puts "3. Handling Invalid Page Numbers"
  puts "-" * 40

  result = doc_tool.execute(
    action: SharedTools::Tools::DocTool::Action::PDF_READ,
    doc_path: sample_pdf,
    page_numbers: "1, 999"
  )

  puts "Requested pages: 1, 999"
  puts "Valid pages: #{result[:pages].size}"
  puts "Invalid pages: #{result[:invalid_pages].inspect}"
  puts "The tool automatically filters out invalid page numbers."
  puts

  # Example 4: Extract text for search/analysis
  puts "4. Extracting Text for Search"
  puts "-" * 40

  result = doc_tool.execute(
    action: SharedTools::Tools::DocTool::Action::PDF_READ,
    doc_path: sample_pdf,
    page_numbers: "1"
  )

  text = result[:pages].first[:text]

  # Search for specific terms
  search_terms = ['the', 'and', 'of']

  puts "Searching for common words in page 1:"
  search_terms.each do |term|
    count = text.downcase.scan(/\b#{term}\b/).size
    puts "  '#{term}': #{count} occurrences"
  end
  puts

  # Example 5: Extract metadata and statistics
  puts "5. Document Statistics"
  puts "-" * 40

  result = doc_tool.execute(
    action: SharedTools::Tools::DocTool::Action::PDF_READ,
    doc_path: sample_pdf,
    page_numbers: "1, 2, 3"
  )

  total_chars = 0
  total_words = 0
  total_lines = 0

  result[:pages].each do |page|
    text = page[:text] || ""
    total_chars += text.length
    total_words += text.split.size
    total_lines += text.lines.count
  end

  puts "Statistics for pages 1-3:"
  puts "  Total characters: #{total_chars}"
  puts "  Total words: #{total_words}"
  puts "  Total lines: #{total_lines}"
  puts "  Average words per page: #{total_words / result[:pages].size}"
  puts

  # Example 6: Using individual tool directly
  puts "6. Using PdfReaderTool Directly"
  puts "-" * 40
  puts "You can also use the PDF reader tool directly:"
  puts

  pdf_tool = SharedTools::Tools::Doc::PdfReaderTool.new
  result = pdf_tool.execute(
    doc_path: sample_pdf,
    page_numbers: "1"
  )

  puts "Tool: PdfReaderTool"
  puts "Pages extracted: #{result[:pages].size}"
  puts "Total document pages: #{result[:total_pages]}"
  puts

  # Example 7: Practical use case - Extract table of contents
  puts "7. Practical Example - Finding Section Headers"
  puts "-" * 40

  result = doc_tool.execute(
    action: SharedTools::Tools::DocTool::Action::PDF_READ,
    doc_path: sample_pdf,
    page_numbers: "1, 2, 3"
  )

  puts "Looking for potential section headers (all-caps lines):"
  result[:pages].each do |page|
    next unless page[:text]

    lines = page[:text].lines
    headers = lines.select do |line|
      line.strip.length > 5 &&
      line.strip == line.strip.upcase &&
      line.strip.match?(/^[A-Z\s]+$/)
    end

    if headers.any?
      puts "\nPage #{page[:page]}:"
      headers.first(3).each do |header|
        puts "  - #{header.strip}"
      end
    end
  end
  puts

  # Example 8: Batch processing multiple pages
  puts "8. Batch Processing - Word Frequency"
  puts "-" * 40

  # Read first 5 pages or all pages if less than 5
  max_page = [result[:total_pages], 5].min
  page_range = (1..max_page).to_a.join(", ")

  result = doc_tool.execute(
    action: SharedTools::Tools::DocTool::Action::PDF_READ,
    doc_path: sample_pdf,
    page_numbers: page_range
  )

  # Combine all text
  all_text = result[:pages].map { |p| p[:text] }.join(" ")

  # Count word frequencies
  words = all_text.downcase.scan(/\b[a-z]{4,}\b/)
  freq = Hash.new(0)
  words.each { |word| freq[word] += 1 }

  puts "Top 10 most common words (4+ letters) in pages 1-#{max_page}:"
  freq.sort_by { |_, count| -count }.first(10).each_with_index do |(word, count), i|
    puts "  #{i + 1}. '#{word}': #{count} times"
  end
  puts

  # Example 9: Error handling
  puts "9. Error Handling"
  puts "-" * 40

  result = doc_tool.execute(
    action: SharedTools::Tools::DocTool::Action::PDF_READ,
    doc_path: "/nonexistent/file.pdf",
    page_numbers: "1"
  )

  if result[:error]
    puts "Attempting to read non-existent file:"
    puts "Error caught: #{result[:error]}"
    puts "The tool gracefully handles errors and returns error information."
  end
  puts

rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(5)
end

puts "=" * 80
puts "Example completed!"
puts "=" * 80
puts
puts "Key Takeaways:"
puts "- DocTool provides a unified interface for document processing"
puts "- PDF reading supports single pages, multiple pages, and ranges"
puts "- Invalid page numbers are automatically filtered out"
puts "- Extracted text can be used for search, analysis, and processing"
puts "- Error handling is built-in with descriptive error messages"
puts "- Individual tools (PdfReaderTool) can be used directly for more control"
