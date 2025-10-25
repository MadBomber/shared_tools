# Multi-Tool Workflows

This guide demonstrates how to combine multiple SharedTools to create powerful, multi-step workflows. We'll break down the comprehensive workflow example to show patterns and best practices.

## Overview

The [comprehensive_workflow_example.rb](https://github.com/madbomber/shared_tools/blob/main/examples/comprehensive_workflow_example.rb) demonstrates a realistic scenario that many LLM applications face: collecting data from one source, processing it, and generating multiple output formats.

## The Workflow: Web Scraping to Database to Reports

This workflow consists of three distinct phases that demonstrate tool composition:

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Web Scraping  │────▶│ Database Storage │────▶│Report Generation│
│  (BrowserTool)  │     │ (DatabaseTool)   │     │   (DiskTool)    │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

## Phase 1: Web Scraping with BrowserTool

### Setting Up the Browser

The workflow starts by initializing a browser tool with a custom driver:

```ruby
# Mock browser driver for demonstration
class MockBrowserDriver
  def goto(url:)
    @current_url = url
    "Navigated to #{url}"
  end

  def html
    # Returns HTML content based on current URL
    case @current_url
    when /products/
      # Return product catalog HTML
    else
      # Return default HTML
    end
  end

  # Other required methods: click, fill_in, screenshot, close
end

browser_driver = MockBrowserDriver.new
browser = SharedTools::Tools::BrowserTool.new(driver: browser_driver)
```

### Navigating and Extracting Data

```ruby
# Navigate to the products page
browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::VISIT,
  url: "https://example.com/products"
)

# Get the page HTML
html_content = browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::PAGE_INSPECT,
  full_html: true
)

# Parse HTML to extract structured data
require 'nokogiri'
doc = Nokogiri::HTML(html_content)
products = []

doc.css('.product').each do |product_node|
  product = {
    name: product_node.css('h2').text.strip,
    price: product_node.css('.price').text.strip.gsub(/[$,]/, '').to_i,
    category: product_node.css('.category').text.strip
  }
  products << product
end

puts "Found #{products.size} products"
```

### Key Patterns from Phase 1

1. **Custom Drivers**: The workflow uses a mock driver for testing, demonstrating the driver interface pattern
2. **Action Constants**: Uses `BrowserTool::Action::VISIT` and `PAGE_INSPECT` for clarity
3. **External Parsers**: Combines SharedTools with other Ruby gems (Nokogiri) for specialized tasks
4. **Structured Data**: Transforms raw HTML into structured Ruby hashes for downstream processing

## Phase 2: Database Storage with DatabaseTool

### Setting Up the Database

```ruby
# Simple SQLite driver implementation
class SimpleSqliteDriver < SharedTools::Tools::Database::BaseDriver
  def initialize(db:)
    @db = db
  end

  def perform(statement:)
    if statement.match?(/^\s*SELECT/i)
      rows = @db.execute(statement)
      { status: :ok, result: rows }
    else
      @db.execute(statement)
      { status: :ok, result: "Success (#{@db.changes} rows)" }
    end
  rescue SQLite3::Exception => e
    { status: :error, result: e.message }
  end
end

# Initialize database
db = SQLite3::Database.new(':memory:')
db_driver = SimpleSqliteDriver.new(db: db)
database = SharedTools::Tools::DatabaseTool.new(driver: db_driver)
```

### Creating Tables and Inserting Data

```ruby
# Create the products table
database.execute(
  statements: [
    <<~SQL
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        category TEXT NOT NULL,
        scraped_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    SQL
  ]
)

# Insert all scraped products
insert_statements = products.map do |product|
  "INSERT INTO products (name, price, category) " \
  "VALUES ('#{product[:name]}', #{product[:price]}, '#{product[:category]}')"
end

results = database.execute(statements: insert_statements)
puts "Inserted #{results.size} products"
```

### Generating Statistics

```ruby
# Run multiple queries for statistics
stats_results = database.execute(
  statements: [
    "SELECT COUNT(*) as total FROM products",
    "SELECT category, COUNT(*) as count, AVG(price) as avg_price
     FROM products GROUP BY category",
    "SELECT MAX(price) as highest_price, MIN(price) as lowest_price
     FROM products"
  ]
)

# Extract results
total_products = stats_results[0][:result].first[0]
category_stats = stats_results[1][:result]
price_range = stats_results[2][:result].first

puts "Total products: #{total_products}"
category_stats.each do |cat, count, avg|
  puts "- #{cat}: #{count} items, avg price: $#{avg.round(2)}"
end
```

### Key Patterns from Phase 2

1. **Custom Driver Implementation**: Shows how to implement the BaseDriver interface
2. **Error Handling**: The driver catches SQL exceptions and returns structured error responses
3. **Batch Operations**: Executes multiple statements in sequence
4. **Status Checking**: Each result includes a `:status` field (`:ok` or `:error`)
5. **Data Aggregation**: Uses SQL for efficient data processing

## Phase 3: Report Generation with DiskTool

### Setting Up File System Access

```ruby
# Initialize disk tool with a temporary directory
temp_dir = Dir.mktmpdir('scraping_report')
disk = SharedTools::Tools::DiskTool.new(
  driver: SharedTools::Tools::Disk::LocalDriver.new(root: temp_dir)
)

# Create reports directory
disk.execute(
  action: SharedTools::Tools::DiskTool::Action::DIRECTORY_CREATE,
  path: "./reports"
)
```

### Generating Multiple Report Formats

#### Markdown Report

```ruby
# Build report content
report_content = <<~REPORT
  # Product Scraping Report

  Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}

  ## Summary

  - Total Products: #{total_products}
  - Price Range: $#{price_range[1]} - $#{price_range[0]}

  ## Products by Category
REPORT

category_stats.each do |cat, count, avg|
  report_content += "\n### #{cat} (#{count} items, avg: $#{avg.round(2)})\n\n"

  # Query products for this category
  cat_products = database.execute(
    statements: ["SELECT name, price FROM products
                  WHERE category = '#{cat}' ORDER BY price DESC"]
  ).first[:result]

  cat_products.each do |name, price|
    report_content += "- #{name}: $#{price}\n"
  end
end

# Save Markdown report
disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_CREATE,
  path: "./reports/product_report.md"
)

disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_WRITE,
  path: "./reports/product_report.md",
  text: report_content
)
```

#### JSON Export

```ruby
require 'json'

json_data = {
  generated_at: Time.now.iso8601,
  summary: {
    total_products: total_products,
    price_range: { min: price_range[1], max: price_range[0] }
  },
  products: products
}

disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_CREATE,
  path: "./reports/products.json"
)

disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_WRITE,
  path: "./reports/products.json",
  text: JSON.pretty_generate(json_data)
)
```

#### CSV Export

```ruby
csv_content = "Name,Price,Category\n"
products.each do |p|
  csv_content += "#{p[:name]},#{p[:price]},#{p[:category]}\n"
end

disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_CREATE,
  path: "./reports/products.csv"
)

disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_WRITE,
  path: "./reports/products.csv",
  text: csv_content
)
```

### Key Patterns from Phase 3

1. **Multiple Output Formats**: Generates reports in Markdown, JSON, and CSV
2. **Temporary Directories**: Uses Ruby's `Dir.mktmpdir` for safe temporary storage
3. **Structured Output**: Organizes files in a dedicated reports directory
4. **Content Generation**: Builds complex reports by combining database queries with templates
5. **Action Separation**: Uses separate `FILE_CREATE` and `FILE_WRITE` actions for clarity

## Cross-Phase Patterns

### Data Flow

Data flows naturally from one phase to the next:

```ruby
# Phase 1: Extract
products = scrape_products(browser)

# Phase 2: Transform & Store
store_in_database(database, products)
stats = calculate_statistics(database)

# Phase 3: Output
generate_reports(disk, database, products, stats)
```

### Error Handling Across Phases

```ruby
def workflow
  browser = nil
  database = nil

  begin
    # Phase 1
    browser = initialize_browser
    products = scrape_products(browser)
    raise "No products found" if products.empty?

    # Phase 2
    database = initialize_database
    results = store_products(database, products)
    failed = results.select { |r| r[:status] == :error }
    raise "Database errors: #{failed}" unless failed.empty?

    # Phase 3
    disk = initialize_disk
    generate_reports(disk, database, products)

  rescue => e
    puts "Workflow failed: #{e.message}"
    # Cleanup or rollback as needed
  ensure
    browser&.cleanup!
    database&.close
  end
end
```

### Resource Management

```ruby
# Always cleanup resources
begin
  browser = SharedTools::Tools::BrowserTool.new(driver: browser_driver)
  database = SharedTools::Tools::DatabaseTool.new(driver: db_driver)

  # Use tools...

ensure
  browser&.cleanup!
  db&.close
end
```

## Advanced Workflow Patterns

### Parallel Processing

When operations don't depend on each other:

```ruby
# Scrape multiple pages concurrently
require 'concurrent'

urls = ["https://example.com/page1", "https://example.com/page2"]
promises = urls.map do |url|
  Concurrent::Promise.execute do
    browser = SharedTools::Tools::BrowserTool.new
    browser.execute(action: "visit", url: url)
    browser.execute(action: "page_inspect", full_html: true)
  end
end

results = promises.map(&:value)
```

### Incremental Processing

For large datasets, process in chunks:

```ruby
# Process products in batches
products.each_slice(100) do |batch|
  insert_statements = batch.map { |p| generate_insert_sql(p) }
  database.execute(statements: insert_statements)
  puts "Processed batch of #{batch.size}"
end
```

### Conditional Workflows

Adjust workflow based on results:

```ruby
# Conditional report generation
html = browser.execute(action: "page_inspect", full_html: true)
products = parse_products(html)

if products.size > 100
  # Generate full report with all formats
  generate_full_report(disk, products)
elsif products.size > 0
  # Generate summary only
  generate_summary_report(disk, products)
else
  # Just log that nothing was found
  puts "No products to report"
end
```

### Tool Chaining

Create higher-level abstractions:

```ruby
class ScrapingPipeline
  def initialize(browser:, database:, disk:)
    @browser = browser
    @database = database
    @disk = disk
  end

  def execute(url:)
    # Phase 1: Scrape
    products = scrape_from_url(url)

    # Phase 2: Store
    store_products(products)

    # Phase 3: Report
    generate_reports(products)
  end

  private

  def scrape_from_url(url)
    @browser.execute(action: "visit", url: url)
    html = @browser.execute(action: "page_inspect", full_html: true)
    parse_products(html)
  end

  # ... other methods
end

# Usage
pipeline = ScrapingPipeline.new(browser: browser, database: db, disk: disk)
pipeline.execute(url: "https://example.com/products")
```

## Testing Workflows

### Using Mock Drivers

The example demonstrates using mock drivers for testing:

```ruby
class MockBrowserDriver
  def initialize(responses: {})
    @responses = responses
  end

  def html
    @responses[@current_url] || default_html
  end
end

# In tests
responses = {
  "https://test.com/products" => "<html>...</html>"
}
driver = MockBrowserDriver.new(responses: responses)
browser = SharedTools::Tools::BrowserTool.new(driver: driver)
```

### Integration Testing

Test the complete workflow:

```ruby
def test_complete_workflow
  # Setup
  browser = create_test_browser
  database = create_test_database
  disk = create_test_disk

  # Execute
  products = workflow_phase1(browser)
  workflow_phase2(database, products)
  workflow_phase3(disk, database)

  # Verify
  assert File.exist?(temp_dir + "/reports/product_report.md")
  assert_equal expected_products, products
end
```

## Performance Considerations

### Database Connection Pooling

```ruby
# Reuse database connections
class WorkflowExecutor
  def initialize
    @db_pool = ConnectionPool.new(size: 5) do
      SQLite3::Database.new('products.db')
    end
  end

  def execute
    @db_pool.with do |db|
      driver = SimpleSqliteDriver.new(db: db)
      database = SharedTools::Tools::DatabaseTool.new(driver: driver)
      # Use database...
    end
  end
end
```

### Caching Browser Sessions

```ruby
# Reuse browser instances
@browser_cache ||= {}

def get_browser(profile:)
  @browser_cache[profile] ||= begin
    driver = Browser::WatirDriver.new(profile: profile)
    SharedTools::Tools::BrowserTool.new(driver: driver)
  end
end
```

## Real-World Variations

### E-commerce Price Monitoring

```ruby
# Daily price check workflow
browser.execute(action: "visit", url: competitor_url)
prices = extract_prices(browser)
database.execute(statements: [
  "INSERT INTO price_history (product_id, price, date) VALUES (...)"
])
generate_price_alert_if_changed(disk, database)
```

### Content Aggregation

```ruby
# Aggregate content from multiple sources
sources.each do |source|
  browser.execute(action: "visit", url: source[:url])
  articles = extract_articles(browser)
  database.execute(statements: generate_inserts(articles))
end
generate_daily_digest(disk, database)
```

### Data Migration

```ruby
# Migrate data between systems
old_data = database.execute(statements: ["SELECT * FROM legacy_table"])
transformed = transform_data(old_data)
new_database.execute(statements: generate_inserts(transformed))
disk.execute(action: "file_write", path: "./migration_log.txt", text: log)
```

## Next Steps

- Explore individual [Tool Examples](./index.md)
- Learn about [Error Handling Patterns](../guides/error-handling.md)
- Read the [API Reference](../api/index.md) for detailed parameter information
- Check out [Testing Strategies](../guides/testing.md) for workflow testing
