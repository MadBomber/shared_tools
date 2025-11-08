# Doc Tool Example

The DocTool provides an interface for document processing operations, particularly for reading and extracting text from PDF documents.

## Overview

This example demonstrates how to use the DocTool facade to read and extract text from PDF documents. The tool supports reading single pages, multiple pages, and handles invalid page numbers gracefully.

## Example Code

View the complete example: [doc_tool_example.rb](https://github.com/madbomber/shared_tools/blob/main/examples/doc_tool_example.rb)

## Key Features

### 1. Reading a Single Page

Extract text from a specific page:

```ruby
doc_tool = SharedTools::Tools::DocTool.new

result = doc_tool.execute(
  action: SharedTools::Tools::DocTool::Action::PDF_READ,
  doc_path: sample_pdf,
  page_numbers: "1"
)

puts "Total pages: #{result[:total_pages]}"
puts "Page 1 text: #{result[:pages].first[:text]}"
```

### 2. Reading Multiple Pages

Extract text from multiple specific pages:

```ruby
result = doc_tool.execute(
  action: SharedTools::Tools::DocTool::Action::PDF_READ,
  doc_path: sample_pdf,
  page_numbers: "1, 2, 3"
)

result[:pages].each do |page|
  puts "Page #{page[:page]}: #{page[:text].length} characters"
end
```

### 3. Handling Invalid Page Numbers

The tool automatically filters out invalid page numbers:

```ruby
result = doc_tool.execute(
  action: SharedTools::Tools::DocTool::Action::PDF_READ,
  doc_path: sample_pdf,
  page_numbers: "1, 999"
)

puts "Valid pages: #{result[:pages].size}"
puts "Invalid pages: #{result[:invalid_pages].inspect}"
# The tool automatically filters out page 999 if it doesn't exist
```

### 4. Text Extraction and Search

Extract text for search and analysis:

```ruby
result = doc_tool.execute(
  action: SharedTools::Tools::DocTool::Action::PDF_READ,
  doc_path: sample_pdf,
  page_numbers: "1"
)

text = result[:pages].first[:text]

# Search for specific terms
search_terms = ['the', 'and', 'of']

search_terms.each do |term|
  count = text.downcase.scan(/\b#{term}\b/).size
  puts "'#{term}': #{count} occurrences"
end
```

## Document Statistics

Calculate statistics from extracted text:

```ruby
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

puts "Total characters: #{total_chars}"
puts "Total words: #{total_words}"
puts "Average words per page: #{total_words / result[:pages].size}"
```

## Using Individual Tools Directly

You can also use the PDF reader tool directly:

```ruby
pdf_tool = SharedTools::Tools::Doc::PdfReaderTool.new

result = pdf_tool.execute(
  doc_path: sample_pdf,
  page_numbers: "1"
)

puts "Pages extracted: #{result[:pages].size}"
puts "Total document pages: #{result[:total_pages]}"
```

## Practical Examples

### Finding Section Headers

Extract potential section headers from a document:

```ruby
result = doc_tool.execute(
  action: SharedTools::Tools::DocTool::Action::PDF_READ,
  doc_path: sample_pdf,
  page_numbers: "1, 2, 3"
)

result[:pages].each do |page|
  next unless page[:text]

  lines = page[:text].lines
  headers = lines.select do |line|
    line.strip.length > 5 &&
    line.strip == line.strip.upcase &&
    line.strip.match?(/^[A-Z\s]+$/)
  end

  if headers.any?
    puts "Page #{page[:page]}:"
    headers.each { |header| puts "  - #{header.strip}" }
  end
end
```

### Word Frequency Analysis

Analyze word frequency across multiple pages:

```ruby
# Read first 5 pages
result = doc_tool.execute(
  action: SharedTools::Tools::DocTool::Action::PDF_READ,
  doc_path: sample_pdf,
  page_numbers: "1, 2, 3, 4, 5"
)

# Combine all text
all_text = result[:pages].map { |p| p[:text] }.join(" ")

# Count word frequencies
words = all_text.downcase.scan(/\b[a-z]{4,}\b/)
freq = Hash.new(0)
words.each { |word| freq[word] += 1 }

# Show top 10 most common words
freq.sort_by { |_, count| -count }.first(10).each_with_index do |(word, count), i|
  puts "#{i + 1}. '#{word}': #{count} times"
end
```

## Error Handling

The tool gracefully handles errors:

```ruby
result = doc_tool.execute(
  action: SharedTools::Tools::DocTool::Action::PDF_READ,
  doc_path: "/nonexistent/file.pdf",
  page_numbers: "1"
)

if result[:error]
  puts "Error: #{result[:error]}"
  # The tool returns error information instead of raising exceptions
end
```

## Result Structure

```ruby
{
  total_pages: <number of pages in document>,
  requested_pages: <array of requested page numbers>,
  pages: [
    {
      page: <page number>,
      text: <extracted text>
    },
    ...
  ],
  invalid_pages: <array of invalid page numbers>,
  error: <error message if failed>
}
```

## Available Actions

- `PDF_READ` - Read and extract text from PDF pages

## Run the Example

```bash
cd examples
bundle exec ruby doc_tool_example.rb
```

The example requires a test PDF file at `test/fixtures/test.pdf`. If you don't have one, you'll need to provide a sample PDF.

## Related Documentation

- [DocTool Documentation](../tools/doc.md)
- [Facade Pattern](../api/facade-pattern.md)
- [Driver Interface](../api/driver-interface.md)

## Requirements

- The `pdf-reader` gem must be installed (included in SharedTools dependencies)
- A valid PDF file to process

## Key Takeaways

- DocTool provides a unified interface for document processing
- PDF reading supports single pages, multiple pages, and ranges
- Invalid page numbers are automatically filtered out
- Extracted text can be used for search, analysis, and processing
- Error handling is built-in with descriptive error messages
- Individual tools (PdfReaderTool) can be used directly for more control
- Results include metadata about total pages and requested pages

## Use Cases

- Extracting text for full-text search
- Analyzing document content
- Finding specific information in PDFs
- Converting PDF content to other formats
- Document summarization and analysis
- Building document indexing systems
