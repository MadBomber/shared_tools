# DocTool

Read and process document formats, currently supporting PDF files for text extraction.

## Installation

DocTool requires the pdf-reader gem:

```ruby
gem 'pdf-reader', '~> 2.0'
```

## Basic Usage

```ruby
require 'shared_tools'

doc = SharedTools::Tools::DocTool.new

# Read first page
result = doc.execute(
  action: "pdf_read",
  doc_path: "./document.pdf",
  page_numbers: "1"
)

puts result[:pages]  # Array of page content
```

## Actions

### pdf_read

Read specific pages from a PDF document.

**Parameters:**

- `action`: "pdf_read"
- `doc_path`: Path to PDF file
- `page_numbers`: Page numbers to read (comma-separated, supports ranges)

**Page Number Format:**

- Single page: `"1"`
- Multiple pages: `"1, 3, 5"`
- Range: `"1-10"`
- Combined: `"1, 5-8, 15"`

**Examples:**

```ruby
doc = SharedTools::Tools::DocTool.new

# Read first page
result = doc.execute(
  action: "pdf_read",
  doc_path: "./report.pdf",
  page_numbers: "1"
)

# Read specific pages
result = doc.execute(
  action: "pdf_read",
  doc_path: "./book.pdf",
  page_numbers: "1, 10, 20"
)

# Read page range
result = doc.execute(
  action: "pdf_read",
  doc_path: "./manual.pdf",
  page_numbers: "5-15"
)

# Read complex selection
result = doc.execute(
  action: "pdf_read",
  doc_path: "./thesis.pdf",
  page_numbers: "1, 5-8, 15, 20-25"
)
```

## Return Value

The `pdf_read` action returns a hash with:

```ruby
{
  pages: [
    { number: 1, content: "Page 1 text..." },
    { number: 2, content: "Page 2 text..." },
    # ...
  ],
  total_pages: 100,
  requested: "1-5"
}
```

## Complete Examples

### Example 1: Extract Table of Contents

```ruby
require 'shared_tools'

doc = SharedTools::Tools::DocTool.new

# Read first 5 pages (usually contains TOC)
result = doc.execute(
  action: "pdf_read",
  doc_path: "./book.pdf",
  page_numbers: "1-5"
)

# Process pages
toc_lines = []
result[:pages].each do |page|
  lines = page[:content].lines
  lines.each do |line|
    # Find lines that look like TOC entries
    if line =~ /^(Chapter|Section)\s+\d+/
      toc_lines << line.strip
    end
  end
end

puts "Table of Contents:"
puts toc_lines.join("\n")
```

### Example 2: Search for Keywords

```ruby
require 'shared_tools'

doc = SharedTools::Tools::DocTool.new
keyword = "machine learning"

# Read all pages (adjust range as needed)
result = doc.execute(
  action: "pdf_read",
  doc_path: "./research_paper.pdf",
  page_numbers: "1-50"
)

# Search for keyword
matches = []
result[:pages].each do |page|
  if page[:content].downcase.include?(keyword.downcase)
    matches << {
      page: page[:number],
      excerpt: page[:content][0..200] + "..."
    }
  end
end

puts "Found '#{keyword}' on #{matches.size} pages:"
matches.each do |match|
  puts "\nPage #{match[:page]}:"
  puts match[:excerpt]
end
```

### Example 3: Extract and Save Text

```ruby
require 'shared_tools'

doc = SharedTools::Tools::DocTool.new
disk = SharedTools::Tools::DiskTool.new

# Read PDF pages
result = doc.execute(
  action: "pdf_read",
  doc_path: "./document.pdf",
  page_numbers: "1-10"
)

# Combine all page content
full_text = result[:pages].map { |page|
  "=== Page #{page[:number]} ===\n\n#{page[:content]}\n\n"
}.join

# Save to text file
disk.execute(action: "file_create", path: "./extracted.txt")
disk.execute(action: "file_write", path: "./extracted.txt", text: full_text)

puts "Extracted #{result[:pages].size} pages to extracted.txt"
```

### Example 4: PDF Summary Generator

```ruby
require 'shared_tools'

doc = SharedTools::Tools::DocTool.new

# Read document
result = doc.execute(
  action: "pdf_read",
  doc_path: "./report.pdf",
  page_numbers: "1-#{result[:total_pages]}"  # All pages
)

# Generate summary
summary = {
  title: "PDF Summary",
  total_pages: result[:total_pages],
  total_words: 0,
  average_words_per_page: 0,
  pages_with_content: 0
}

result[:pages].each do |page|
  word_count = page[:content].split.size
  summary[:total_words] += word_count
  summary[:pages_with_content] += 1 if word_count > 0
end

summary[:average_words_per_page] =
  summary[:total_words] / summary[:pages_with_content]

puts "Document Summary:"
puts "  Total Pages: #{summary[:total_pages]}"
puts "  Total Words: #{summary[:total_words]}"
puts "  Avg Words/Page: #{summary[:average_words_per_page]}"
```

### Example 5: Multi-Document Processing

```ruby
require 'shared_tools'

doc = SharedTools::Tools::DocTool.new
pdf_files = Dir.glob("./documents/*.pdf")

results = pdf_files.map do |pdf_path|
  puts "Processing #{pdf_path}..."

  result = doc.execute(
    action: "pdf_read",
    doc_path: pdf_path,
    page_numbers: "1"  # Read first page only
  )

  {
    file: File.basename(pdf_path),
    pages: result[:total_pages],
    first_page: result[:pages].first[:content][0..200]
  }
end

# Generate report
puts "\n" + "=" * 80
puts "Document Processing Report"
puts "=" * 80

results.each do |r|
  puts "\nFile: #{r[:file]}"
  puts "  Pages: #{r[:pages]}"
  puts "  Preview: #{r[:first_page]}..."
end
```

## Working with Large PDFs

### Strategy 1: Read in Chunks

```ruby
doc = SharedTools::Tools::DocTool.new

# For a 1000-page PDF, read in chunks
chunk_size = 50
total_pages = 1000

(1..total_pages).step(chunk_size) do |start_page|
  end_page = [start_page + chunk_size - 1, total_pages].min

  result = doc.execute(
    action: "pdf_read",
    doc_path: "./large_document.pdf",
    page_numbers: "#{start_page}-#{end_page}"
  )

  # Process this chunk
  process_pages(result[:pages])

  puts "Processed pages #{start_page}-#{end_page}"
end
```

### Strategy 2: Read Specific Sections

```ruby
# Only read pages you need
important_pages = "1, 5, 10-15, 50, 100-110"

result = doc.execute(
  action: "pdf_read",
  doc_path: "./large_document.pdf",
  page_numbers: important_pages
)
```

## Error Handling

```ruby
doc = SharedTools::Tools::DocTool.new

# Handle file not found
begin
  doc.execute(
    action: "pdf_read",
    doc_path: "./missing.pdf",
    page_numbers: "1"
  )
rescue Errno::ENOENT => e
  puts "PDF not found: #{e.message}"
end

# Handle invalid page numbers
begin
  doc.execute(
    action: "pdf_read",
    doc_path: "./document.pdf",
    page_numbers: "999"  # Beyond last page
  )
rescue StandardError => e
  puts "Invalid page number: #{e.message}"
end

# Handle corrupted PDF
begin
  doc.execute(
    action: "pdf_read",
    doc_path: "./corrupted.pdf",
    page_numbers: "1"
  )
rescue PDF::Reader::MalformedPDFError => e
  puts "Corrupted PDF: #{e.message}"
end
```

## Text Extraction Limitations

DocTool extracts raw text from PDFs, which has some limitations:

### What Works Well:

- Plain text documents
- Simple formatting
- Basic tables (as text)
- Standard fonts

### Limitations:

- **Images**: Not extracted (OCR not supported)
- **Complex layouts**: May not preserve exact formatting
- **Tables**: Extracted as text, not structured data
- **Fonts**: Embedded fonts work, but special characters may vary
- **Encryption**: Password-protected PDFs not supported

### Handling These Limitations:

```ruby
# Check if page has content
result[:pages].each do |page|
  if page[:content].strip.empty?
    puts "Page #{page[:number]} appears to be empty (possibly image-only)"
  else
    puts "Page #{page[:number]} has text content"
  end
end
```

## Best Practices

### 1. Check File Exists First

```ruby
pdf_path = "./document.pdf"

if File.exist?(pdf_path)
  result = doc.execute(
    action: "pdf_read",
    doc_path: pdf_path,
    page_numbers: "1"
  )
else
  puts "PDF not found: #{pdf_path}"
end
```

### 2. Validate Page Numbers

```ruby
# Get total pages first
result = doc.execute(
  action: "pdf_read",
  doc_path: "./document.pdf",
  page_numbers: "1"
)

total_pages = result[:total_pages]

# Now read valid range
desired_page = 100
if desired_page <= total_pages
  result = doc.execute(
    action: "pdf_read",
    doc_path: "./document.pdf",
    page_numbers: desired_page.to_s
  )
else
  puts "Page #{desired_page} exceeds total pages (#{total_pages})"
end
```

### 3. Handle Large Documents Efficiently

```ruby
# Don't read all pages at once for large PDFs
# Use ranges to read what you need
result = doc.execute(
  action: "pdf_read",
  doc_path: "./large.pdf",
  page_numbers: "1-10"  # Start with first 10 pages
)
```

### 4. Clean Extracted Text

```ruby
result[:pages].each do |page|
  # Remove extra whitespace
  cleaned = page[:content].gsub(/\s+/, ' ').strip

  # Remove page numbers if present
  cleaned = cleaned.gsub(/^Page \d+\s*/, '')

  puts cleaned
end
```

## Troubleshooting

### PDF-Reader Gem Not Found

```
Error: cannot load such file -- pdf-reader
```

**Solution:** Install the gem:

```bash
gem install pdf-reader
```

### Corrupted PDF Error

```
PDF::Reader::MalformedPDFError
```

**Solution:** Try repairing the PDF with external tools:

```bash
# Using Ghostscript
gs -o repaired.pdf -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress original.pdf
```

### Empty Text Extraction

If text is empty but you know the PDF has content:

1. PDF might be image-based (scanned document) - requires OCR
2. PDF might use non-standard encoding
3. PDF might be encrypted

### Memory Issues with Large PDFs

```
Error: memory allocation failed
```

**Solution:** Read in smaller chunks:

```ruby
# Instead of reading all pages
# Read in chunks of 50 pages
(1..total_pages).step(50) do |start_page|
  end_page = [start_page + 49, total_pages].min
  result = doc.execute(
    action: "pdf_read",
    doc_path: "./large.pdf",
    page_numbers: "#{start_page}-#{end_page}"
  )
  # Process and discard before next chunk
end
```

## See Also

- [Basic Usage](../getting-started/basic-usage.md) - Common patterns
- [DiskTool](disk.md) - Save extracted text to files
- [EvalTool](eval.md) - Process extracted text with code
- [Examples](https://github.com/madbomber/shared_tools/tree/main/examples/doc_tool_example.rb)
