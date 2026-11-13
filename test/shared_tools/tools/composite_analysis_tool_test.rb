# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class CompositeAnalysisToolTest < Minitest::Test
  SALES_CSV = <<~CSV
    id,product,sales,revenue,category
    1,Widget A,100,1000.50,Electronics
    2,Widget B,150,2250.75,Electronics
    3,Gadget C,80,960.00,Home
    4,Tool D,120,1800.00,Tools
    5,Widget E,90,1350.00,Electronics
  CSV

  USERS_JSON = <<~JSON
    {"users": [
      {"id": 1, "name": "Alice", "age": 30, "score": 85},
      {"id": 2, "name": "Bob", "age": 25, "score": 92},
      {"id": 3, "name": "Charlie", "age": 35, "score": 78}
    ]}
  JSON

  Response = SharedTools::Tools::HttpHelpers::Response

  def setup
    @tool = SharedTools::Tools::CompositeAnalysisTool.new
    @dir = Dir.mktmpdir("composite_analysis_test")
    @csv = File.join(@dir, "test.csv")
    File.write(@csv, SALES_CSV)
    File.write(File.join(@dir, "data.csv"), SALES_CSV)
    File.write(File.join(@dir, "data.json"), USERS_JSON)
    File.write(File.join(@dir, "data.txt"), "line one\nline two\nline three\n")
  end

  def teardown
    FileUtils.rm_rf(@dir) if @dir
  end

  # Run the block with guarded_get stubbed to return +body+ for any URL.
  def with_web_response(body, content_type: "text/plain", status: 200, &block)
    response = Response.new(status: status, headers: { "content-type" => [content_type] },
                            body: body, final_url: "https://example.com/stubbed")
    @tool.stub(:guarded_get, response, &block)
  end

  def test_tool_name
    assert_equal 'composite_analysis', SharedTools::Tools::CompositeAnalysisTool.tool_name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  # Basic analysis tests
  def test_analyzes_csv_file
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    assert_equal "file", result[:analysis][:source_type]
    assert result[:analysis][:structure]
    assert result[:analysis][:insights]
  end

  def test_analyzes_json_url
    result = with_web_response(USERS_JSON, content_type: "application/json") do
      @tool.execute(data_source: "https://example.com/data.json")
    end

    assert result[:success], result[:error]
    assert_equal "web", result[:analysis][:source_type]
    assert_equal "json", result[:analysis][:structure][:data_type]
  end

  def test_analyzes_api_url
    result = with_web_response('{"status": "ok", "data": [1, 2, 3]}', content_type: "application/json") do
      @tool.execute(data_source: "https://api.example.com/data")
    end

    assert result[:success], result[:error]
    assert_equal "web", result[:analysis][:source_type]
  end

  # Real sources only: no simulated data (#30)
  def test_analyzes_the_real_csv_columns
    path = File.join(@dir, "real.csv")
    File.write(path, "city,temp\nDenver,61\nBoulder,58\n")

    result = @tool.execute(data_source: path)

    assert result[:success], result[:error]
    assert_equal %w[city temp], result[:analysis][:structure][:columns].map { |c| c[:name] }
    assert_equal 2, result[:analysis][:structure][:row_count]
  end

  def test_csv_url_body_is_parsed_with_csv
    result = with_web_response("city,temp\nDenver,61\n\"Fort Collins, CO\",57\n", content_type: "text/csv") do
      @tool.execute(data_source: "https://example.com/weather")
    end

    assert result[:success], result[:error]
    assert_equal %w[city temp], result[:analysis][:structure][:columns].map { |c| c[:name] }
    assert_equal 2, result[:analysis][:structure][:row_count]
  end

  def test_missing_json_file_returns_error
    result = @tool.execute(data_source: File.join(@dir, "missing.json"))

    refute result[:success]
    assert_includes result[:error], "File not found"
  end

  def test_http_error_status_returns_error
    result = with_web_response("not found", status: 404) do
      @tool.execute(data_source: "https://example.com/x.csv")
    end

    refute result[:success]
    assert_includes result[:error], "HTTP 404"
  end

  def test_fetch_failure_returns_error
    failing = ->(_url) { raise SharedTools::Tools::HttpHelpers::FetchError, "getaddrinfo: nodename nor servname provided" }
    result = @tool.stub(:guarded_get, failing) do
      @tool.execute(data_source: "https://example.invalid/x.csv")
    end

    refute result[:success]
    assert_includes result[:error], "getaddrinfo"
  end

  def test_blocked_url_returns_error
    result = @tool.execute(data_source: "http://127.0.0.1/x.csv")

    refute result[:success]
    assert result[:error]
  end

  def test_parse_fetched_body
    assert_equal [{ "a" => "1", "b" => "2" }],
                 @tool.send(:parse_fetched_body, "a,b\n1,2\n", "text/csv; charset=utf-8", "https://x.test/data")
    assert_equal [{ "a" => "1", "b" => "2" }],
                 @tool.send(:parse_fetched_body, "a,b\n1,2\n", "text/plain", "https://x.test/data.CSV?x=1")
    assert_equal({ "a" => 1 },
                 @tool.send(:parse_fetched_body, '{"a": 1}', "application/json", "https://x.test/data"))
  end

  def test_read_file_data_by_extension
    assert_equal 5, @tool.send(:read_file_data, @csv).length
    assert @tool.send(:read_file_data, File.join(@dir, "data.json")).key?("users")
    assert_equal ["line one", "line two", "line three"], @tool.send(:read_file_data, File.join(@dir, "data.txt"))
    assert_raises(ArgumentError) { @tool.send(:read_file_data, File.join(@dir, "nope.csv")) }
  end

  # Analysis type tests
  def test_quick_analysis_skips_insights
    result = @tool.execute(
      data_source: @csv,
      analysis_type: "quick"
    )

    assert result[:success]
    assert result[:analysis][:structure]
    refute result[:analysis][:insights]
  end

  def test_standard_analysis_includes_insights
    result = @tool.execute(
      data_source: @csv,
      analysis_type: "standard"
    )

    assert result[:success]
    assert result[:analysis][:structure]
    assert result[:analysis][:insights]
  end

  def test_comprehensive_analysis_includes_correlations
    result = @tool.execute(
      data_source: @csv,
      analysis_type: "comprehensive"
    )

    assert result[:success]
    assert result[:analysis][:structure]
    assert result[:analysis][:insights]
    assert result[:analysis][:correlations]
  end

  def test_default_analysis_type_is_standard
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    assert_equal "standard", result[:analysis_type]
    assert result[:analysis][:insights]
  end

  # Data structure analysis tests
  def test_identifies_numeric_columns
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    structure = result[:analysis][:structure]
    assert structure[:numeric_columns]
    assert structure[:numeric_columns].any? { |c| c[:name] == "sales" }
  end

  def test_identifies_categorical_columns
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    structure = result[:analysis][:structure]
    assert structure[:categorical_columns]
    assert structure[:categorical_columns].any? { |c| c[:name] == "category" }
  end

  def test_counts_rows_correctly
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    assert_equal 5, result[:analysis][:structure][:row_count]
  end

  def test_identifies_data_type
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    assert_equal "tabular", result[:analysis][:structure][:data_type]
  end

  # Insights generation tests
  def test_generates_summary
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    insights = result[:analysis][:insights]
    assert insights[:summary]
    assert_includes insights[:summary], "rows"
  end

  def test_assesses_data_quality
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    quality = result[:analysis][:insights][:quality]
    assert quality[:completeness]
    assert quality[:quality_score]
  end

  def test_provides_recommendations
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    recommendations = result[:analysis][:insights][:recommendations]
    assert recommendations
    assert recommendations.is_a?(Array)
    assert recommendations.length > 0
  end

  def test_calculates_statistics_for_numeric_columns
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    stats = result[:analysis][:insights][:statistics]
    assert stats
    assert stats["sales"]
    assert stats["sales"][:min]
    assert stats["sales"][:max]
    assert stats["sales"][:mean]
  end

  # Visualization suggestion tests
  def test_suggests_visualizations_for_numeric_data
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    viz = result[:analysis][:visualizations]
    assert viz
    assert viz.any? { |v| v[:type] == "histogram" }
  end

  def test_suggests_scatter_plots_for_numeric_pairs
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    viz = result[:analysis][:visualizations]
    assert viz.any? { |v| v[:type] == "scatter_plot" }
  end

  def test_limits_visualization_suggestions
    result = @tool.execute(
      data_source: @csv,
      visualization_limit: 2
    )

    assert result[:success]
    viz = result[:analysis][:visualizations]
    assert viz.length <= 2
  end

  def test_visualizations_have_priority
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    viz = result[:analysis][:visualizations]
    assert viz.all? { |v| v[:priority] }
  end

  # Correlation analysis tests
  def test_correlation_analysis_requires_multiple_numeric_columns
    result = @tool.execute(
      data_source: @csv,
      analysis_type: "comprehensive"
    )

    assert result[:success]
    assert result[:analysis][:correlations]
    assert result[:analysis][:correlations][:pairs]
  end

  def test_identifies_strongest_correlation
    result = @tool.execute(
      data_source: @csv,
      analysis_type: "comprehensive"
    )

    assert result[:success]
    assert result[:analysis][:correlations][:strongest]
    assert result[:analysis][:correlations][:strongest][:columns]
    assert result[:analysis][:correlations][:strongest][:correlation]
  end

  def test_correlation_strength_interpretation
    result = @tool.execute(
      data_source: @csv,
      analysis_type: "comprehensive"
    )

    assert result[:success]
    correlations = result[:analysis][:correlations][:pairs]
    assert correlations.all? { |c| ['weak', 'moderate', 'strong'].include?(c[:strength]) }
  end

  def test_can_disable_correlation_analysis
    result = @tool.execute(
      data_source: @csv,
      analysis_type: "comprehensive",
      include_correlations: false
    )

    assert result[:success]
    refute result[:analysis][:correlations]
  end

  # Options handling tests
  def test_accepts_empty_options
    result = @tool.execute(
      data_source: @csv,
      options: {}
    )

    assert result[:success]
  end

  def test_handles_sample_size_option
    result = @tool.execute(
      data_source: @csv,
      sample_size: 100
    )

    assert result[:success]
  end

  # Error handling tests
  def test_missing_file_returns_error
    result = @tool.execute(data_source: "/nonexistent/path/file.csv")

    refute result[:success]
    assert_includes result[:error], "File not found: /nonexistent/path/file.csv"
    assert_equal "/nonexistent/path/file.csv", result[:data_source]
  end

  def test_returns_error_info_on_failure
    # This test would need special setup to trigger an actual error
    # For now, verify error structure is correct
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    assert result[:analyzed_at]
    assert result[:duration_seconds]
  end

  # Metadata tests
  def test_includes_analysis_timestamp
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    assert result[:analyzed_at]
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, result[:analyzed_at])
  end

  def test_includes_duration
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    assert result[:duration_seconds]
    assert result[:duration_seconds] >= 0
  end

  def test_includes_source_information
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    assert_equal @csv, result[:data_source]
    assert_equal "file", result[:analysis][:source_type]
  end

  # Web vs file detection tests
  def test_detects_http_urls
    result = with_web_response(SALES_CSV) { @tool.execute(data_source: "http://example.com/data") }

    assert result[:success], result[:error]
    assert_equal "web", result[:analysis][:source_type]
  end

  def test_detects_https_urls
    result = with_web_response(SALES_CSV) { @tool.execute(data_source: "https://example.com/data") }

    assert result[:success], result[:error]
    assert_equal "web", result[:analysis][:source_type]
  end

  def test_treats_non_urls_as_files
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    assert_equal "file", result[:analysis][:source_type]
  end

  # Pattern identification tests
  def test_identifies_patterns_in_categorical_data
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    patterns = result[:analysis][:insights][:patterns]
    assert patterns
    assert patterns["category"]
    assert patterns["category"][:most_common]
  end

  def test_pattern_includes_distribution
    result = @tool.execute(data_source: @csv)

    assert result[:success]
    patterns = result[:analysis][:insights][:patterns]
    assert patterns["category"][:distribution]
    assert patterns["category"][:distribution].is_a?(Hash)
  end

  # Complete workflow test
  def test_complete_analysis_workflow
    result = with_web_response(SALES_CSV, content_type: "text/csv") do
      @tool.execute(
        data_source: "https://example.com/sales.csv",
        analysis_type: "comprehensive",
        visualization_limit: 3,
        include_correlations: true
      )
    end

    assert result[:success], result[:error]

    # Verify all analysis components
    assert result[:analysis][:structure]
    assert result[:analysis][:insights]
    assert result[:analysis][:visualizations]
    assert result[:analysis][:correlations]

    # Verify metadata
    assert result[:data_source]
    assert result[:analysis_type]
    assert result[:analyzed_at]
    assert result[:duration_seconds]
  end

  # Edge cases
  def test_handles_empty_options
    result = @tool.execute(
      data_source: @csv,
      analysis_type: "standard",
      options: {}
    )

    assert result[:success]
  end

  def test_handles_different_file_extensions
    [".csv", ".json", ".txt"].each do |ext|
      result = @tool.execute(data_source: File.join(@dir, "data#{ext}"))
      assert result[:success], "Should handle #{ext} files"
    end
  end
end
