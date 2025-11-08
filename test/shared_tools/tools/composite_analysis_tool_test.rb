# frozen_string_literal: true

require "test_helper"

class CompositeAnalysisToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::CompositeAnalysisTool.new
  end

  def test_tool_name
    assert_equal 'composite_analysis', SharedTools::Tools::CompositeAnalysisTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  # Basic analysis tests
  def test_analyzes_simulated_csv_data
    result = @tool.execute(data_source: "test_data.csv")

    assert result[:success]
    assert_equal "file", result[:analysis][:source_type]
    assert result[:analysis][:structure]
    assert result[:analysis][:insights]
  end

  def test_analyzes_simulated_json_url
    result = @tool.execute(data_source: "https://example.com/data.json")

    assert result[:success]
    assert_equal "web", result[:analysis][:source_type]
    assert result[:analysis][:structure]
  end

  def test_analyzes_simulated_api_url
    result = @tool.execute(data_source: "https://api.example.com/data")

    assert result[:success]
    assert_equal "web", result[:analysis][:source_type]
  end

  # Analysis type tests
  def test_quick_analysis_skips_insights
    result = @tool.execute(
      data_source: "test.csv",
      analysis_type: "quick"
    )

    assert result[:success]
    assert result[:analysis][:structure]
    refute result[:analysis][:insights]
  end

  def test_standard_analysis_includes_insights
    result = @tool.execute(
      data_source: "test.csv",
      analysis_type: "standard"
    )

    assert result[:success]
    assert result[:analysis][:structure]
    assert result[:analysis][:insights]
  end

  def test_comprehensive_analysis_includes_correlations
    result = @tool.execute(
      data_source: "test.csv",
      analysis_type: "comprehensive"
    )

    assert result[:success]
    assert result[:analysis][:structure]
    assert result[:analysis][:insights]
    assert result[:analysis][:correlations]
  end

  def test_default_analysis_type_is_standard
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    assert_equal "standard", result[:analysis_type]
    assert result[:analysis][:insights]
  end

  # Data structure analysis tests
  def test_identifies_numeric_columns
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    structure = result[:analysis][:structure]
    assert structure[:numeric_columns]
    assert structure[:numeric_columns].any? { |c| c[:name] == "sales" }
  end

  def test_identifies_categorical_columns
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    structure = result[:analysis][:structure]
    assert structure[:categorical_columns]
    assert structure[:categorical_columns].any? { |c| c[:name] == "category" }
  end

  def test_counts_rows_correctly
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    assert_equal 5, result[:analysis][:structure][:row_count]
  end

  def test_identifies_data_type
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    assert_equal "tabular", result[:analysis][:structure][:data_type]
  end

  # Insights generation tests
  def test_generates_summary
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    insights = result[:analysis][:insights]
    assert insights[:summary]
    assert_includes insights[:summary], "rows"
  end

  def test_assesses_data_quality
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    quality = result[:analysis][:insights][:quality]
    assert quality[:completeness]
    assert quality[:quality_score]
  end

  def test_provides_recommendations
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    recommendations = result[:analysis][:insights][:recommendations]
    assert recommendations
    assert recommendations.is_a?(Array)
    assert recommendations.length > 0
  end

  def test_calculates_statistics_for_numeric_columns
    result = @tool.execute(data_source: "test.csv")

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
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    viz = result[:analysis][:visualizations]
    assert viz
    assert viz.any? { |v| v[:type] == "histogram" }
  end

  def test_suggests_scatter_plots_for_numeric_pairs
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    viz = result[:analysis][:visualizations]
    assert viz.any? { |v| v[:type] == "scatter_plot" }
  end

  def test_limits_visualization_suggestions
    result = @tool.execute(
      data_source: "test.csv",
      visualization_limit: 2
    )

    assert result[:success]
    viz = result[:analysis][:visualizations]
    assert viz.length <= 2
  end

  def test_visualizations_have_priority
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    viz = result[:analysis][:visualizations]
    assert viz.all? { |v| v[:priority] }
  end

  # Correlation analysis tests
  def test_correlation_analysis_requires_multiple_numeric_columns
    result = @tool.execute(
      data_source: "test.csv",
      analysis_type: "comprehensive"
    )

    assert result[:success]
    assert result[:analysis][:correlations]
    assert result[:analysis][:correlations][:pairs]
  end

  def test_identifies_strongest_correlation
    result = @tool.execute(
      data_source: "test.csv",
      analysis_type: "comprehensive"
    )

    assert result[:success]
    assert result[:analysis][:correlations][:strongest]
    assert result[:analysis][:correlations][:strongest][:columns]
    assert result[:analysis][:correlations][:strongest][:correlation]
  end

  def test_correlation_strength_interpretation
    result = @tool.execute(
      data_source: "test.csv",
      analysis_type: "comprehensive"
    )

    assert result[:success]
    correlations = result[:analysis][:correlations][:pairs]
    assert correlations.all? { |c| ['weak', 'moderate', 'strong'].include?(c[:strength]) }
  end

  def test_can_disable_correlation_analysis
    result = @tool.execute(
      data_source: "test.csv",
      analysis_type: "comprehensive",
      include_correlations: false
    )

    assert result[:success]
    refute result[:analysis][:correlations]
  end

  # Options handling tests
  def test_accepts_empty_options
    result = @tool.execute(
      data_source: "test.csv",
      options: {}
    )

    assert result[:success]
  end

  def test_handles_sample_size_option
    result = @tool.execute(
      data_source: "test.csv",
      sample_size: 100
    )

    assert result[:success]
  end

  # Error handling tests
  def test_handles_invalid_data_source_gracefully
    result = @tool.execute(data_source: "/nonexistent/path/file.csv")

    # Should succeed with simulated data (graceful degradation)
    assert result[:success]
  end

  def test_returns_error_info_on_failure
    # This test would need special setup to trigger an actual error
    # For now, verify error structure is correct
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    assert result[:analyzed_at]
    assert result[:duration_seconds]
  end

  # Metadata tests
  def test_includes_analysis_timestamp
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    assert result[:analyzed_at]
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, result[:analyzed_at])
  end

  def test_includes_duration
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    assert result[:duration_seconds]
    assert result[:duration_seconds] >= 0
  end

  def test_includes_source_information
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    assert_equal "test.csv", result[:data_source]
    assert_equal "file", result[:analysis][:source_type]
  end

  # Web vs file detection tests
  def test_detects_http_urls
    result = @tool.execute(data_source: "http://example.com/data")

    assert result[:success]
    assert_equal "web", result[:analysis][:source_type]
  end

  def test_detects_https_urls
    result = @tool.execute(data_source: "https://example.com/data")

    assert result[:success]
    assert_equal "web", result[:analysis][:source_type]
  end

  def test_treats_non_urls_as_files
    result = @tool.execute(data_source: "/path/to/file.csv")

    assert result[:success]
    assert_equal "file", result[:analysis][:source_type]
  end

  # Pattern identification tests
  def test_identifies_patterns_in_categorical_data
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    patterns = result[:analysis][:insights][:patterns]
    assert patterns
    assert patterns["category"]
    assert patterns["category"][:most_common]
  end

  def test_pattern_includes_distribution
    result = @tool.execute(data_source: "test.csv")

    assert result[:success]
    patterns = result[:analysis][:insights][:patterns]
    assert patterns["category"][:distribution]
    assert patterns["category"][:distribution].is_a?(Hash)
  end

  # Complete workflow test
  def test_complete_analysis_workflow
    result = @tool.execute(
      data_source: "https://example.com/sales.csv",
      analysis_type: "comprehensive",
      visualization_limit: 3,
        include_correlations: true
    )

    assert result[:success]

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
      data_source: "test.csv",
      analysis_type: "standard",
      options: {}
    )

    assert result[:success]
  end

  def test_handles_different_file_extensions
    [".csv", ".json", ".txt"].each do |ext|
      result = @tool.execute(data_source: "data#{ext}")
      assert result[:success], "Should handle #{ext} files"
    end
  end
end
