#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: DocTool
#
# Shows how an LLM uses the DocTool to read and reason over document
# content — plain text, PDF, and Microsoft Word (.docx) files.
#
# For PDF support install:  gem install pdf-reader
# For DOCX support install: gem install docx
#
# Run:
#   bundle exec ruby -I examples examples/doc_tool_demo.rb

ENV['RUBY_LLM_DEBUG'] = 'true'

require_relative 'common'
require 'shared_tools/doc_tool'

require 'tmpdir'
require 'fileutils'

# Build a minimal but valid .docx file from an array of paragraph strings.
# A DOCX is a ZIP containing XML files; this uses rubyzip (pulled in by the
# docx gem) to create one from scratch without needing Word or caracal.
def build_docx(path, paragraphs)
  require 'zip'

  para_xml = paragraphs.map do |text|
    escaped = text.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
    "<w:p><w:r><w:t xml:space=\"preserve\">#{escaped}</w:t></w:r></w:p>"
  end.join

  ns = 'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"'
  pkg = 'xmlns="http://schemas.openxmlformats.org/package/2006/content-types"'
  rel = 'xmlns="http://schemas.openxmlformats.org/package/2006/relationships"'
  off = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'

  content_types = %(<Types #{pkg}><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/></Types>)
  pkg_rels  = %(<Relationships #{rel}><Relationship Id="rId1" Type="#{off}/officeDocument" Target="word/document.xml"/></Relationships>)
  word_rels = %(<Relationships #{rel}></Relationships>)
  styles    = %(<w:styles #{ns}></w:styles>)
  doc       = %(<w:document #{ns}><w:body>#{para_xml}</w:body></w:document>)

  Zip::File.open(path, create: true) do |zip|
    zip.get_output_stream('[Content_Types].xml')          { |f| f.write(content_types) }
    zip.get_output_stream('_rels/.rels')                  { |f| f.write(pkg_rels) }
    zip.get_output_stream('word/_rels/document.xml.rels') { |f| f.write(word_rels) }
    zip.get_output_stream('word/styles.xml')              { |f| f.write(styles) }
    zip.get_output_stream('word/document.xml')            { |f| f.write(doc) }
  end
end

# Build a multi-sheet .xlsx file from a hash of { sheet_name => [[row], [row], ...] }.
# Values may be strings or numbers; strings are stored in the sharedStrings table.
def build_xlsx(path, sheets_data)
  require 'zip'

  # Collect all unique string values across all sheets
  all_strings = []
  sheets_data.each_value do |rows|
    rows.each { |row| row.each { |v| all_strings << v.to_s if v.is_a?(String) } }
  end
  all_strings = all_strings.uniq

  str_index = all_strings.each_with_index.to_h  # string => index

  ns_main = 'xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
  ns_r    = 'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"'
  pkg_ns  = 'xmlns="http://schemas.openxmlformats.org/package/2006/content-types"'
  rel_ns  = 'xmlns="http://schemas.openxmlformats.org/package/2006/relationships"'
  off     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'

  sheet_names  = sheets_data.keys
  sheet_xmls   = {}
  override_xml = sheet_names.each_with_index.map do |_, i|
    %(<Override PartName="/xl/worksheets/sheet#{i+1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>)
  end.join

  content_types = %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types #{pkg_ns}><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>#{override_xml}</Types>)

  pkg_rels = %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships #{rel_ns}><Relationship Id="rId1" Type="#{off}/officeDocument" Target="xl/workbook.xml"/></Relationships>)

  wb_rels_entries = sheet_names.each_with_index.map do |_, i|
    %(<Relationship Id="rId#{i+1}" Type="#{off}/worksheet" Target="worksheets/sheet#{i+1}.xml"/>)
  end
  wb_rels_entries << %(<Relationship Id="rId#{sheet_names.size+1}" Type="#{off}/sharedStrings" Target="sharedStrings.xml"/>)
  wb_rels_entries << %(<Relationship Id="rId#{sheet_names.size+2}" Type="#{off}/styles" Target="styles.xml"/>)
  wb_rels = %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships #{rel_ns}>#{wb_rels_entries.join}</Relationships>)

  sheet_els = sheet_names.each_with_index.map do |name, i|
    %(<sheet name="#{name}" sheetId="#{i+1}" r:id="rId#{i+1}"/>)
  end.join
  workbook = %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook #{ns_main} #{ns_r}><sheets>#{sheet_els}</sheets></workbook>)

  sst_items = all_strings.map { |s| "<si><t>#{s.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;')}</t></si>" }.join
  shared_strings = %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?><sst #{ns_main} count="#{all_strings.size}" uniqueCount="#{all_strings.size}">#{sst_items}</sst>)

  styles = %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?><styleSheet #{ns_main}><fonts><font><sz val="11"/><name val="Calibri"/></font></fonts><fills><fill><patternFill patternType="none"/></fill></fills><borders><border><left/><right/><top/><bottom/><diagonal/></border></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs></styleSheet>)

  col_letters = ('A'..'Z').to_a

  sheet_names.each_with_index do |name, si|
    rows = sheets_data[name]
    row_xml = rows.each_with_index.map do |row, ri|
      row_num = ri + 1
      cells = row.each_with_index.map do |val, ci|
        col = col_letters[ci]
        ref = "#{col}#{row_num}"
        if val.is_a?(String)
          %(<c r="#{ref}" t="s"><v>#{str_index[val]}</v></c>)
        else
          %(<c r="#{ref}"><v>#{val}</v></c>)
        end
      end.join
      %(<row r="#{row_num}">#{cells}</row>)
    end.join
    sheet_xmls[name] = %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet #{ns_main}><sheetData>#{row_xml}</sheetData></worksheet>)
  end

  Zip::File.open(path, create: true) do |zip|
    zip.get_output_stream('[Content_Types].xml')        { |f| f.write(content_types) }
    zip.get_output_stream('_rels/.rels')                { |f| f.write(pkg_rels) }
    zip.get_output_stream('xl/_rels/workbook.xml.rels') { |f| f.write(wb_rels) }
    zip.get_output_stream('xl/workbook.xml')            { |f| f.write(workbook) }
    zip.get_output_stream('xl/sharedStrings.xml')       { |f| f.write(shared_strings) }
    zip.get_output_stream('xl/styles.xml')              { |f| f.write(styles) }
    sheet_names.each_with_index do |name, i|
      zip.get_output_stream("xl/worksheets/sheet#{i+1}.xml") { |f| f.write(sheet_xmls[name]) }
    end
  end
end

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

  title "DOCX — Read a Word Document", char: '-'
  docx_path = File.join(work_dir, 'meeting_notes.docx')
  build_docx(docx_path, [
    "Q1 2026 Engineering Planning Meeting",
    "Date: March 25, 2026  |  Attendees: Alice, Bob, Carol, Dave",
    "Agenda Item 1: Release v3.0 Timeline",
    "Target release date confirmed as April 30, 2026. Alice will own the release checklist. Bob flagged three open P1 bugs that must be resolved before the release branch is cut.",
    "Agenda Item 2: Infrastructure Migration",
    "The team agreed to migrate staging from AWS us-east-1 to us-west-2 by April 10. Carol will coordinate with DevOps. Estimated downtime: 2 hours on a Saturday morning.",
    "Agenda Item 3: Hiring",
    "Two senior engineer requisitions approved. Dave will post the job descriptions by March 28. Target start date for new hires: June 1, 2026.",
    "Action Items",
    "Alice: Publish release checklist by March 27.",
    "Bob: Fix P1 bugs by April 15.",
    "Carol: Schedule infrastructure migration for April 5.",
    "Dave: Post job descriptions by March 28.",
    "Next Meeting: April 8, 2026 at 10am PST."
  ])

  @chat = new_chat.with_tool(SharedTools::Tools::DocTool.new)
  ask "Read the Word document at '#{docx_path}' and summarise the key decisions and action items from this meeting."

  ask "Who owns the infrastructure migration, and when is it scheduled?"

  ask "How many action items are there, and who is responsible for each one?"

  title "Spreadsheet — Read a CSV file", char: '-'
  csv_path = File.join(work_dir, 'expenses.csv')
  File.write(csv_path, <<~CSV)
    Month,Category,Amount,Approved
    January,Travel,1240.50,true
    January,Software,89.99,true
    February,Travel,875.00,true
    February,Hardware,2400.00,false
    March,Travel,1100.75,true
    March,Software,179.98,true
    March,Office Supplies,342.00,true
    April,Travel,650.00,true
    April,Hardware,3200.00,true
    April,Software,89.99,true
  CSV

  @chat = new_chat.with_tool(SharedTools::Tools::DocTool.new)
  ask "Read the spreadsheet at '#{csv_path}'. What is the total spend by category? Which month had the highest travel expenses?"

  ask "Are there any unapproved expenses in '#{csv_path}'? Show me the details."

  title "Spreadsheet — Read a Multi-Sheet XLSX", char: '-'
  xlsx_path = File.join(work_dir, 'quarterly_sales.xlsx')
  build_xlsx(xlsx_path, {
    "Q1" => [
      ["Product", "Jan", "Feb", "Mar", "Total"],
      ["Widget A", 12400, 11800, 13200, 37400],
      ["Widget B",  8200,  7600,  9100, 24900],
      ["Widget C",  3100,  2900,  3800,  9800],
    ],
    "Q2" => [
      ["Product", "Apr", "May", "Jun", "Total"],
      ["Widget A", 14100, 15300, 16200, 45600],
      ["Widget B",  7900,  8400,  9200, 25500],
      ["Widget C",  4800,  5100,  6300, 16200],
    ],
    "Summary" => [
      ["Product", "Q1 Total", "Q2 Total", "Growth %"],
      ["Widget A", 37400, 45600, 21.9],
      ["Widget B", 24900, 25500,  2.4],
      ["Widget C",  9800, 16200, 65.3],
    ]
  })

  @chat = new_chat.with_tool(SharedTools::Tools::DocTool.new)
  ask "Read the 'Summary' sheet from '#{xlsx_path}'. Which product had the strongest growth from Q1 to Q2?"

  ask "Now read the 'Q2' sheet from '#{xlsx_path}'. What was the best-performing product in June?"

  ask "Read both the 'Q1' and 'Q2' sheets from '#{xlsx_path}' and compare Widget C's trajectory. Is the growth sustainable?"

ensure
  FileUtils.rm_rf(work_dir)
  puts "\nTemporary documents removed."
end

title "Done", char: '-'
puts "DocTool let the LLM read and reason over text, PDF, Word, and spreadsheet documents."
