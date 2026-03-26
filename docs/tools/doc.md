# DocTool

Read and process document files including plain text, PDF, Microsoft Word (.docx), and spreadsheets (CSV, XLSX, ODS, XLSM).

## Installation

Install optional gems depending on the formats you need:

```ruby
gem 'pdf-reader', '~> 2.0'   # PDF support
gem 'docx'                    # Word (.docx) support
gem 'roo'                     # Spreadsheet support (CSV, XLSX, ODS, XLSM)
```

## Basic Usage

```ruby
require 'shared_tools'
require 'shared_tools/doc_tool'

doc = SharedTools::Tools::DocTool.new

# Read a plain text file
result = doc.execute(action: "text_read", doc_path: "./notes.txt")

# Read a PDF
result = doc.execute(action: "pdf_read", doc_path: "./report.pdf", page_numbers: "1-5")

# Read a Word document
result = doc.execute(action: "docx_read", doc_path: "./meeting.docx")

# Read a spreadsheet
result = doc.execute(action: "spreadsheet_read", doc_path: "./data.csv")
```

## Actions

### text_read

Read the full contents of a plain text file (.txt, .md, etc.).

**Parameters:**

- `action`: `"text_read"`
- `doc_path`: Path to the text file

**Example:**

```ruby
result = doc.execute(
  action: "text_read",
  doc_path: "./README.md"
)
puts result[:content]
```

---

### pdf_read

Read specific pages from a PDF document.

**Parameters:**

- `action`: `"pdf_read"`
- `doc_path`: Path to the PDF file
- `page_numbers`: Pages to read — single (`"5"`), list (`"1, 3, 5"`), range (`"1-10"`), or combined (`"1, 5-8, 15"`)

**Examples:**

```ruby
doc = SharedTools::Tools::DocTool.new

# Read first page
result = doc.execute(action: "pdf_read", doc_path: "./report.pdf", page_numbers: "1")

# Read a range
result = doc.execute(action: "pdf_read", doc_path: "./book.pdf", page_numbers: "10-15")

# Read complex selection
result = doc.execute(action: "pdf_read", doc_path: "./manual.pdf", page_numbers: "1, 5-8, 15, 20-25")
```

**Return value:**

```ruby
{
  pages: [
    { number: 1, content: "Page 1 text..." },
    { number: 2, content: "Page 2 text..." }
  ],
  total_pages: 100,
  requested: "1-5"
}
```

---

### docx_read

Read text content from a Microsoft Word (.docx) document.

**Parameters:**

- `action`: `"docx_read"`
- `doc_path`: Path to the .docx file
- `paragraph_range` *(optional)*: Paragraphs to read, same notation as `page_numbers`. Omit to return the full document.

**Examples:**

```ruby
# Read the full document
result = doc.execute(action: "docx_read", doc_path: "./report.docx")

# Read only the first 20 paragraphs
result = doc.execute(
  action: "docx_read",
  doc_path: "./report.docx",
  paragraph_range: "1-20"
)
```

**Return value:**

```ruby
{
  paragraphs: [
    { number: 1, text: "Introduction" },
    { number: 2, text: "This document covers..." }
  ],
  total_paragraphs: 42,
  requested: "1-20"
}
```

---

### spreadsheet_read

Read tabular data from a spreadsheet file. Supports CSV, XLSX, ODS, and XLSM formats.

**Parameters:**

- `action`: `"spreadsheet_read"`
- `doc_path`: Path to the spreadsheet file
- `sheet` *(optional)*: Sheet name or 1-based index for multi-sheet workbooks (defaults to first sheet)
- `row_range` *(optional)*: Rows to read, e.g. `"2-100"` (defaults to all rows)
- `headers` *(optional)*: When `true` (default), treats the first row as column headers and returns each row as a hash

**Examples:**

```ruby
# Read a CSV file
result = doc.execute(action: "spreadsheet_read", doc_path: "./data.csv")

# Read a specific sheet from an Excel workbook
result = doc.execute(
  action: "spreadsheet_read",
  doc_path: "./report.xlsx",
  sheet: "Q1 Sales"
)

# Read by sheet index
result = doc.execute(
  action: "spreadsheet_read",
  doc_path: "./report.xlsx",
  sheet: "2"
)

# Read rows 2-50, raw arrays (no header treatment)
result = doc.execute(
  action: "spreadsheet_read",
  doc_path: "./data.xlsx",
  row_range: "2-50",
  headers: false
)
```

**Return value (with headers):**

```ruby
{
  rows: [
    { "Month" => "January", "Amount" => "1240.50", "Approved" => "true" },
    { "Month" => "February", "Amount" => "875.00", "Approved" => "true" }
  ],
  row_count: 2,
  sheet: "Sheet1"
}
```

## Integration with LLM Agents

The DocTool is designed for LLM agents that need to read and reason over documents:

```ruby
require 'ruby_llm'
require 'shared_tools/doc_tool'

chat = RubyLLM.chat.with_tool(SharedTools::Tools::DocTool.new)

# The LLM can read and summarise any supported document type
chat.ask("Read the file './meeting_notes.docx' and summarise the action items.")
chat.ask("Read the 'Summary' sheet from './quarterly_sales.xlsx'. Which product grew the most?")
chat.ask("From './style_guide.txt', what are the naming conventions for constants?")
```

## Supported Formats

| Format | Action | Gem required |
|--------|--------|-------------|
| Plain text (.txt, .md, etc.) | `text_read` | None |
| PDF | `pdf_read` | `pdf-reader` |
| Microsoft Word (.docx) | `docx_read` | `docx` |
| CSV | `spreadsheet_read` | `roo` |
| Excel (.xlsx) | `spreadsheet_read` | `roo` |
| OpenDocument (.ods) | `spreadsheet_read` | `roo` |
| Excel macro-enabled (.xlsm) | `spreadsheet_read` | `roo` |

## Error Handling

```ruby
result = doc.execute(action: "pdf_read", doc_path: "./missing.pdf", page_numbers: "1")
if result[:error]
  puts "DocTool error: #{result[:error]}"
end
```

Common errors and solutions:

- **`pdf-reader` not found** — run `gem install pdf-reader`
- **`docx` not found** — run `gem install docx`
- **`roo` not found** — run `gem install roo`
- **File not found** — check the path and working directory
- **Empty text extraction from PDF** — the PDF may be image-based (scanned); OCR is not supported

## Best Practices

- Use `text_read` for `.txt` and `.md` files — it is lightweight and requires no extra gems.
- For large PDFs, request only the pages you need with `page_numbers`.
- For multi-sheet workbooks, always specify `sheet` to avoid ambiguity.
- Pair with **DiskTool** to save extracted content to a new file.
- Pair with **DnsTool** or **WeatherTool** for workflows that mix documents with live data.

## See Also

- [DiskTool](disk.md) - Save extracted content to files
- [EvalTool](eval.md) - Process extracted text with code
- [DatabaseTool](database.md) - Store extracted data in a database
