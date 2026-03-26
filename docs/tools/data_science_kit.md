# DataScienceKit

Statistical analysis, correlation, time series analysis, clustering, and prediction — performed by the tool itself using real math, not simulated results.

## Basic Usage

```ruby
require 'shared_tools'
require 'shared_tools/data_science_kit'

kit = SharedTools::Tools::DataScienceKit.new

# Analyse a CSV file
result = kit.execute(
  analysis_type: "statistical_summary",
  data_source: "./sales_data.csv"
)

# Pass data inline as a pipe-delimited table
result = kit.execute(
  analysis_type: "correlation_analysis",
  data: <<~TABLE
    | month | revenue | expenses |
    | Jan   | 12400   | 8200     |
    | Feb   | 11800   | 7900     |
    | Mar   | 13200   | 8500     |
  TABLE
)
```

## Analysis Types

### statistical_summary

Descriptive statistics: count, mean, median, standard deviation, min, max, and quartiles for every numeric column.

```ruby
kit.execute(analysis_type: "statistical_summary", data_source: "./data.csv")
```

---

### correlation_analysis

Pearson correlation coefficients between all pairs of numeric columns. Identifies which variables move together.

```ruby
kit.execute(analysis_type: "correlation_analysis", data_source: "./data.csv")
```

---

### time_series

Trend detection, moving averages, and basic seasonality analysis. Requires a date/time column and a numeric value column.

```ruby
kit.execute(
  analysis_type: "time_series",
  data_source: "./monthly_revenue.csv",
  date_column: "month",
  value_column: "revenue"
)
```

---

### clustering

K-means clustering to group similar records. Returns cluster assignments and centroids.

```ruby
kit.execute(
  analysis_type: "clustering",
  data_source: "./customers.csv",
  n_clusters: 3
)
```

---

### prediction

Simple linear regression to predict a target column from one or more feature columns.

```ruby
kit.execute(
  analysis_type: "prediction",
  data_source: "./sales.csv",
  target_column: "revenue",
  feature_columns: ["ad_spend", "headcount"]
)
```

## Data Sources

### File-based (`data_source`)

Pass a path to a CSV or JSON file:

```ruby
kit.execute(analysis_type: "statistical_summary", data_source: "./data.csv")
kit.execute(analysis_type: "statistical_summary", data_source: "./records.json")
```

### Inline data (`data`)

Pass raw data directly as a string. The tool parses these formats automatically:

**Pipe-delimited table** (easiest for LLMs to generate):

```ruby
kit.execute(
  analysis_type: "statistical_summary",
  data: <<~TABLE
    | name    | score | age |
    | Alice   | 88    | 29  |
    | Bob     | 72    | 34  |
    | Carol   | 95    | 27  |
  TABLE
)
```

**CSV string:**

```ruby
kit.execute(
  analysis_type: "statistical_summary",
  data: "name,score,age\nAlice,88,29\nBob,72,34"
)
```

**JSON array of objects:**

```ruby
kit.execute(
  analysis_type: "statistical_summary",
  data: '[{"name":"Alice","score":88},{"name":"Bob","score":72}]'
)
```

**Comma-separated numbers** (for single-series analysis):

```ruby
kit.execute(
  analysis_type: "statistical_summary",
  data: "12, 45, 67, 23, 89, 34"
)
```

## Integration with LLM Agents

The inline `data` parameter makes DataScienceKit ideal for LLM agents — the model can embed the data directly in the tool call without needing to write a file first:

```ruby
require 'ruby_llm'
require 'shared_tools/data_science_kit'

chat = RubyLLM.chat.with_tool(SharedTools::Tools::DataScienceKit.new)

chat.ask(<<~PROMPT)
  Analyse the following sales data and provide a statistical summary.
  Pass the data using the inline 'data' parameter as a pipe-delimited table.

  | quarter | revenue | units_sold | returns |
  | Q1      | 124000  | 1240       | 38      |
  | Q2      | 118000  | 1180       | 45      |
  | Q3      | 132000  | 1320       | 29      |
  | Q4      | 156000  | 1560       | 22      |
PROMPT
```

## Real Computation

DataScienceKit performs genuine calculations on the data you provide:

- **Statistical summary** — mean, median, standard deviation, quartiles computed from actual values
- **Correlation** — Pearson r computed between real column pairs
- **Time series** — moving averages and trend lines derived from actual data points
- **Clustering** — real k-means iteration over your data
- **Prediction** — actual linear regression coefficients fit to your data

Results are not simulated or canned — they reflect the data you pass in.

## See Also

- [CompositeAnalysisTool](index.md) - Higher-level analysis orchestration
- [DocTool](doc.md) - Read spreadsheet data before analysing it
- [DatabaseQueryTool](database.md) - Query a database then analyse the results
