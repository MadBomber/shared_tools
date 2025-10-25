#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Comprehensive Workflow - Web Scraping to Database
#
# This example demonstrates using multiple SharedTools together in a
# realistic workflow: scraping data from a web page, storing it in a
# database, and saving a report to disk.

require 'bundler/setup'
require 'shared_tools'
require 'tmpdir'
require 'fileutils'

begin
  require 'sqlite3'
rescue LoadError
  puts "Error: This example requires the 'sqlite3' gem."
  puts "Install it with: gem install sqlite3"
  exit 1
end

puts "=" * 80
puts "Comprehensive Workflow Example"
puts "Web Scraping → Database Storage → Report Generation"
puts "=" * 80
puts

# ============================================================================
# Setup: Create mock drivers and tools
# ============================================================================

# Mock browser driver that returns sample HTML
class MockBrowserDriver
  def goto(url:)
    @current_url = url
    "Navigated to #{url}"
  end

  def html
    case @current_url
    when /products/
      <<~HTML
        <html>
          <body>
            <h1>Product Catalog</h1>
            <div class="products">
              <div class="product">
                <h2>Laptop Pro</h2>
                <p class="price">$1299</p>
                <p class="category">Electronics</p>
              </div>
              <div class="product">
                <h2>Wireless Mouse</h2>
                <p class="price">$29</p>
                <p class="category">Electronics</p>
              </div>
              <div class="product">
                <h2>Office Chair</h2>
                <p class="price">$249</p>
                <p class="category">Furniture</p>
              </div>
              <div class="product">
                <h2>Desk Lamp</h2>
                <p class="price">$45</p>
                <p class="category">Furniture</p>
              </div>
            </div>
          </body>
        </html>
      HTML
    else
      "<html><body><h1>Home Page</h1></body></html>"
    end
  end

  def click(selector:); end
  def fill_in(selector:, text:); end
  def screenshot; end
  def close; end
end

# Simple SQLite driver
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

# ============================================================================
# Phase 1: Web Scraping
# ============================================================================

puts "PHASE 1: Web Scraping"
puts "-" * 80

# Initialize browser tool
browser_driver = MockBrowserDriver.new
browser = SharedTools::Tools::BrowserTool.new(driver: browser_driver)

# Navigate to products page
puts "1. Navigating to products page..."
browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::VISIT,
  url: "https://example.com/products"
)

# Get page content
puts "2. Extracting product data from HTML..."
html_content = browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::PAGE_INSPECT,
  full_html: true
)

# Parse HTML and extract products (simplified parsing)
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

puts "   Found #{products.size} products:"
products.each do |p|
  puts "   - #{p[:name]} (#{p[:category]}): $#{p[:price]}"
end
puts

# ============================================================================
# Phase 2: Database Storage
# ============================================================================

puts "PHASE 2: Database Storage"
puts "-" * 80

# Initialize database
db = SQLite3::Database.new(':memory:')
db_driver = SimpleSqliteDriver.new(db: db)
database = SharedTools::Tools::DatabaseTool.new(driver: db_driver)

# Create products table
puts "1. Creating products table..."
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

# Insert scraped products
puts "2. Storing products in database..."
insert_statements = products.map do |product|
  "INSERT INTO products (name, price, category) VALUES ('#{product[:name]}', #{product[:price]}, '#{product[:category]}')"
end

results = database.execute(statements: insert_statements)
puts "   Inserted #{results.size} products"
puts

# Query to verify storage
puts "3. Verifying data storage..."
results = database.execute(
  statements: ["SELECT name, price, category FROM products ORDER BY category, price DESC"]
)
stored_products = results.first[:result]
puts "   Database contains:"
stored_products.each do |row|
  puts "   - #{row[0]} (#{row[2]}): $#{row[1]}"
end
puts

# Generate statistics
puts "4. Generating statistics..."
stats_results = database.execute(
  statements: [
    "SELECT COUNT(*) as total FROM products",
    "SELECT category, COUNT(*) as count, AVG(price) as avg_price FROM products GROUP BY category",
    "SELECT MAX(price) as highest_price, MIN(price) as lowest_price FROM products"
  ]
)

total_products = stats_results[0][:result].first[0]
category_stats = stats_results[1][:result]
price_range = stats_results[2][:result].first

puts "   Total products: #{total_products}"
puts "   By category:"
category_stats.each do |cat, count, avg|
  puts "     - #{cat}: #{count} items, avg price: $#{avg.round(2)}"
end
puts "   Price range: $#{price_range[1]} - $#{price_range[0]}"
puts

# ============================================================================
# Phase 3: Report Generation
# ============================================================================

puts "PHASE 3: Report Generation"
puts "-" * 80

# Initialize disk tool
temp_dir = Dir.mktmpdir('scraping_report')
disk = SharedTools::Tools::DiskTool.new(
  driver: SharedTools::Tools::Disk::LocalDriver.new(root: temp_dir)
)

# Create report directory
puts "1. Creating report directory..."
disk.execute(
  action: SharedTools::Tools::DiskTool::Action::DIRECTORY_CREATE,
  path: "./reports"
)

# Generate report content
puts "2. Generating report content..."
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

  # Get products for this category
  cat_products = database.execute(
    statements: ["SELECT name, price FROM products WHERE category = '#{cat}' ORDER BY price DESC"]
  ).first[:result]

  cat_products.each do |name, price|
    report_content += "- #{name}: $#{price}\n"
  end
end

# Save report
puts "3. Saving report to disk..."
disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_CREATE,
  path: "./reports/product_report.md"
)

disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_WRITE,
  path: "./reports/product_report.md",
  text: report_content
)

# Save JSON data
puts "4. Saving JSON data..."
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

# Save CSV data
puts "5. Saving CSV data..."
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

# List generated files
puts "\n6. Report files generated:"
file_list = disk.execute(
  action: SharedTools::Tools::DiskTool::Action::DIRECTORY_LIST,
  path: "./reports"
)
puts file_list
puts

# Display report preview
puts "7. Report preview:"
puts "-" * 40
report = disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_READ,
  path: "./reports/product_report.md"
)
puts report
puts

# ============================================================================
# Cleanup
# ============================================================================

puts "=" * 80
puts "Workflow Summary"
puts "=" * 80
puts
puts "✓ Scraped #{products.size} products from web page"
puts "✓ Stored data in SQLite database"
puts "✓ Generated 3 report files:"
puts "  - product_report.md (Markdown report)"
puts "  - products.json (JSON data)"
puts "  - products.csv (CSV export)"
puts
puts "Report location: #{temp_dir}/reports/"
puts

# Keep temp directory for inspection
puts "NOTE: Temporary directory preserved for inspection:"
puts "  #{temp_dir}"
puts
puts "To clean up, run: rm -rf #{temp_dir}"
puts

browser.cleanup!
db.close

puts "=" * 80
puts "Comprehensive workflow completed successfully!"
puts "=" * 80
