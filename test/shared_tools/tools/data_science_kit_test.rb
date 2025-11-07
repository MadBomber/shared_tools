# frozen_string_literal: true

require "test_helper"

class DataScienceKitTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::DataScienceKit.new
  end

  def test_tool_name
    assert_equal 'data_science_kit', SharedTools::Tools::DataScienceKit.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  # Statistical Summary Tests
  def test_statistical_summary_basic
    result = @tool.execute(
      analysis_type: "statistical_summary",
      data_source: "test_data.csv"
    )

    assert result[:success]
    assert_equal "statistical_summary", result[:analysis_type]
    assert result[:result][:column_statistics]
    assert result[:result][:total_records]
  end

  def test_statistical_summary_includes_quartiles
    result = @tool.execute(
      analysis_type: "statistical_summary",
      data_source: "test.csv",
      parameters: {include_quartiles: true}
    )

    assert result[:success]
    stats = result[:result][:column_statistics].values.first
    assert stats[:q1]
    assert stats[:q3]
    assert stats[:iqr]
  end

  def test_statistical_summary_detects_outliers
    result = @tool.execute(
      analysis_type: "statistical_summary",
      data_source: "test.csv",
      parameters: {outlier_method: "iqr", include_quartiles: true}
    )

    assert result[:success]
    stats = result[:result][:column_statistics].values.first
    assert stats[:outliers]
    assert stats[:outliers][:count]
  end

  def test_statistical_summary_provides_recommendations
    result = @tool.execute(
      analysis_type: "statistical_summary",
      data_source: "test.csv"
    )

    assert result[:success]
    assert result[:result][:recommendations]
    assert result[:result][:recommendations].is_a?(Array)
  end

  # Correlation Analysis Tests
  def test_correlation_analysis_basic
    result = @tool.execute(
      analysis_type: "correlation_analysis",
      data_source: "test_data.csv"
    )

    assert result[:success]
    assert_equal "correlation_analysis", result[:analysis_type]
    assert result[:result][:correlations]
    assert result[:result][:strongest_correlation]
  end

  def test_correlation_analysis_pearson_method
    result = @tool.execute(
      analysis_type: "correlation_analysis",
      data_source: "test.csv",
      parameters: {method: "pearson"}
    )

    assert result[:success]
    assert_equal "pearson", result[:result][:method]
  end

  def test_correlation_analysis_includes_strength
    result = @tool.execute(
      analysis_type: "correlation_analysis",
      data_source: "test.csv"
    )

    assert result[:success]
    corr = result[:result][:correlations].first
    assert corr[:strength]
    assert ['weak', 'moderate', 'strong'].include?(corr[:strength])
  end

  def test_correlation_analysis_significance
    result = @tool.execute(
      analysis_type: "correlation_analysis",
      data_source: "test.csv",
      parameters: {significance_level: 0.05}
    )

    assert result[:success]
    corr = result[:result][:correlations].first
    assert corr.key?(:significant)
  end

  # Time Series Analysis Tests
  def test_time_series_analysis_basic
    result = @tool.execute(
      analysis_type: "time_series",
      data_source: "timeseries.csv"
    )

    assert result[:success]
    assert_equal "time_series", result[:analysis_type]
    assert result[:result][:trend]
    assert result[:result][:forecast]
  end

  def test_time_series_detects_trend
    result = @tool.execute(
      analysis_type: "time_series",
      data_source: "test.csv"
    )

    assert result[:success]
    trend = result[:result][:trend]
    assert trend[:direction]
    assert trend[:slope]
    assert trend[:interpretation]
  end

  def test_time_series_generates_forecast
    result = @tool.execute(
      analysis_type: "time_series",
      data_source: "test.csv",
      parameters: {forecast_periods: 5}
    )

    assert result[:success]
    forecast = result[:result][:forecast]
    assert_equal 5, forecast[:periods]
    assert_equal 5, forecast[:values].length
  end

  def test_time_series_includes_statistics
    result = @tool.execute(
      analysis_type: "time_series",
      data_source: "test.csv"
    )

    assert result[:success]
    stats = result[:result][:statistics]
    assert stats[:mean]
    assert stats[:volatility]
    assert stats[:min]
    assert stats[:max]
  end

  # Clustering Tests
  def test_clustering_basic
    result = @tool.execute(
      analysis_type: "clustering",
      data_source: "test_data.csv"
    )

    assert result[:success]
    assert_equal "clustering", result[:analysis_type]
    assert result[:result][:clusters]
    assert result[:result][:n_clusters]
  end

  def test_clustering_kmeans_algorithm
    result = @tool.execute(
      analysis_type: "clustering",
      data_source: "test.csv",
      parameters: {algorithm: "kmeans", n_clusters: 3}
    )

    assert result[:success]
    assert_equal "kmeans", result[:result][:algorithm]
    assert_equal 3, result[:result][:n_clusters]
  end

  def test_clustering_includes_cluster_stats
    result = @tool.execute(
      analysis_type: "clustering",
      data_source: "test.csv"
    )

    assert result[:success]
    clusters = result[:result][:clusters]
    assert clusters.is_a?(Hash)

    cluster = clusters.values.first
    assert cluster[:size]
    assert cluster[:percentage]
    assert cluster[:centroid]
  end

  def test_clustering_quality_metrics
    result = @tool.execute(
      analysis_type: "clustering",
      data_source: "test.csv"
    )

    assert result[:success]
    assert result[:result][:quality_metrics]
    assert result[:result][:quality_metrics][:inertia]
  end

  # Prediction Tests
  def test_prediction_basic
    result = @tool.execute(
      analysis_type: "prediction",
      data_source: "test_data.csv",
      parameters: {target_column: "value"}
    )

    assert result[:success]
    assert_equal "prediction", result[:analysis_type]
    assert result[:result][:model_type]
    assert result[:result][:performance]
  end

  def test_prediction_requires_target_column
    result = @tool.execute(
      analysis_type: "prediction",
      data_source: "test.csv"
    )

    refute result[:success]
    assert_includes result[:error], "target_column"
  end

  def test_prediction_includes_performance_metrics
    result = @tool.execute(
      analysis_type: "prediction",
      data_source: "test.csv",
      parameters: {target_column: "score"}
    )

    assert result[:success]
    perf = result[:result][:performance]
    assert perf[:mse]
    assert perf[:rmse]
    assert perf[:mae]
    assert perf[:r_squared]
  end

  def test_prediction_feature_importance
    result = @tool.execute(
      analysis_type: "prediction",
      data_source: "test.csv",
      parameters: {target_column: "score"}
    )

    assert result[:success]
    importance = result[:result][:feature_importance]
    assert importance.is_a?(Array)
    assert importance.first[:feature]
    assert importance.first[:importance]
  end

  def test_prediction_validation_split
    result = @tool.execute(
      analysis_type: "prediction",
      data_source: "test.csv",
      parameters: {
        target_column: "score",
        validation_split: 0.3
      }
    )

    assert result[:success]
    assert result[:result][:training_samples]
    assert result[:result][:test_samples]
  end

  # Data Source Tests
  def test_loads_from_file_path
    result = @tool.execute(
      analysis_type: "statistical_summary",
      data_source: "./data/test.csv"
    )

    assert result[:success]
    assert result[:data_summary]
  end

  def test_loads_from_url
    result = @tool.execute(
      analysis_type: "statistical_summary",
      data_source: "https://example.com/data.json"
    )

    assert result[:success]
    assert result[:data_summary]
  end

  def test_loads_from_database_query
    result = @tool.execute(
      analysis_type: "statistical_summary",
      data_source: "SELECT * FROM table"
    )

    assert result[:success]
    assert result[:data_summary]
  end

  # Validation Tests
  def test_rejects_invalid_analysis_type
    result = @tool.execute(
      analysis_type: "invalid_type",
      data_source: "test.csv"
    )

    refute result[:success]
    assert_includes result[:error], "Invalid analysis type"
    assert result[:valid_types]
  end

  def test_validates_time_series_requires_date_column
    result = @tool.execute(
      analysis_type: "time_series",
      data_source: "test.csv",
      parameters: {date_column: "nonexistent_date"}
    )

    refute result[:success]
    assert_includes result[:error], "date column"
  end

  # Data Summary Tests
  def test_includes_data_summary
    result = @tool.execute(
      analysis_type: "statistical_summary",
      data_source: "test.csv"
    )

    assert result[:success]
    summary = result[:data_summary]
    assert summary[:total_records]
    assert summary[:total_columns]
    assert summary[:numeric_columns]
    assert summary[:categorical_columns]
  end

  def test_data_summary_detects_column_types
    result = @tool.execute(
      analysis_type: "statistical_summary",
      data_source: "test.csv"
    )

    assert result[:success]
    summary = result[:data_summary]
    assert summary[:numeric_columns].is_a?(Array)
    assert summary[:categorical_columns].is_a?(Array)
  end

  # Metadata Tests
  def test_includes_timestamp
    result = @tool.execute(
      analysis_type: "statistical_summary",
      data_source: "test.csv"
    )

    assert result[:success]
    assert result[:analyzed_at]
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, result[:analyzed_at])
  end

  def test_includes_duration
    result = @tool.execute(
      analysis_type: "statistical_summary",
      data_source: "test.csv"
    )

    assert result[:success]
    assert result[:duration_seconds]
    assert result[:duration_seconds] >= 0
  end

  # Error Handling Tests
  def test_handles_errors_gracefully
    result = @tool.execute(
      analysis_type: "correlation_analysis",
      data_source: "test.csv"
    )

    # Should return result (with sample data) or error
    assert result.key?(:success)
    assert result.key?(:error) || result.key?(:result)
  end

  def test_error_includes_analysis_type
    result = @tool.execute(
      analysis_type: "invalid",
      data_source: "test.csv"
    )

    refute result[:success]
    assert_equal "invalid", result[:analysis_type]
  end

  # Parameters Tests
  def test_accepts_empty_parameters
    result = @tool.execute(
      analysis_type: "statistical_summary",
      data_source: "test.csv",
      parameters: {}
    )

    assert result[:success]
  end

  def test_uses_default_parameters
    result = @tool.execute(
      analysis_type: "clustering",
      data_source: "test.csv"
    )

    assert result[:success]
    # Should use default n_clusters = 3
    assert_equal 3, result[:result][:n_clusters]
  end

  # Multiple Analysis Types Test
  def test_all_valid_analysis_types
    analysis_types = [
      "statistical_summary",
      "correlation_analysis",
      "time_series",
      "clustering"
    ]

    analysis_types.each do |type|
      result = @tool.execute(
        analysis_type: type,
        data_source: "test.csv"
      )

      assert result[:success], "#{type} should succeed"
      assert_equal type, result[:analysis_type]
    end
  end

  # Prediction with different target columns
  def test_prediction_different_target_columns
    ["value", "score", "metric_x"].each do |target|
      result = @tool.execute(
        analysis_type: "prediction",
        data_source: "test.csv",
        parameters: {target_column: target}
      )

      assert result[:success], "Should predict for #{target}"
      assert_equal target, result[:result][:target_column]
    end
  end
end
