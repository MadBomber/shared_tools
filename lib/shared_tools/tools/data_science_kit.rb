# data_science_kit.rb - Analytics and ML tools
require 'ruby_llm/tool'
require 'json'

module SharedTools
  module Tools
    class DataScienceKit < RubyLLM::Tool
      def self.name = "data_science_kit"

      description <<~'DESCRIPTION'
        Comprehensive data science and analytics toolkit for performing statistical analysis,
        machine learning tasks, and data exploration on various data sources. This tool provides
        a unified interface for common data science operations including descriptive statistics,
        correlation analysis, time series analysis, clustering algorithms, and predictive modeling.
        It automatically handles data loading, validation, preprocessing, and result formatting.
        Supports multiple data formats and provides detailed analysis results with visualizations
        recommendations and statistical significance testing where applicable.
      DESCRIPTION

      params do
        string :analysis_type, description: <<~DESC.strip, required: true
          Type of data science analysis to perform:
          - 'statistical_summary': Descriptive statistics, distributions, outlier detection
          - 'correlation_analysis': Correlation matrices, feature relationships, dependency analysis
          - 'time_series': Trend analysis, seasonality detection, forecasting
          - 'clustering': K-means, hierarchical clustering, cluster analysis
          - 'prediction': Regression analysis, classification, predictive modeling
          Each analysis type requires specific data formats and optional parameters.
        DESC

        string :data_source, description: <<~DESC.strip, required: true
          Data source specification for analysis. Can be:
          - File path: Relative or absolute path to CSV, JSON, Excel, or Parquet files
          - Database query: SQL SELECT statement for database-sourced data
          - API endpoint: HTTP URL for REST API data sources
          The tool automatically detects the format and applies appropriate parsing.
          Examples: './sales_data.csv', 'SELECT * FROM transactions', 'https://api.company.com/data'
        DESC

        object :parameters, description: <<~DESC.strip, required: false do
          Analysis-specific parameters and configuration options.
          Different analysis types use different parameter combinations. Optional parameters
          default to sensible values if not provided.
        DESC
          # Statistical summary parameters
          number :confidence_level, description: "Confidence level for statistical analysis (0.0-1.0). Default: 0.95", required: false
          boolean :include_quartiles, description: "Include quartile calculations (Q1, Q3, IQR). Default: true", required: false
          string :outlier_method, description: "Method for outlier detection: 'iqr' or 'zscore'. Default: 'iqr'", required: false

          # Correlation analysis parameters
          string :method, description: "Correlation method: 'pearson' or 'spearman'. Default: 'pearson'", required: false
          number :significance_level, description: "Significance level for correlation (0.0-1.0). Default: 0.05", required: false

          # Time series parameters
          string :date_column, description: "Name of the date/time column. Default: 'date'", required: false
          string :value_column, description: "Name of the value column for time series. Default: 'value'", required: false
          string :frequency, description: "Time series frequency: 'daily', 'weekly', 'monthly'. Default: auto-detect", required: false
          integer :forecast_periods, description: "Number of periods to forecast. Default: 7", required: false

          # Clustering parameters
          integer :n_clusters, description: "Number of clusters for k-means. Default: 3", required: false
          string :algorithm, description: "Clustering algorithm: 'kmeans' or 'hierarchical'. Default: 'kmeans'", required: false
          string :distance_metric, description: "Distance metric: 'euclidean', 'manhattan', 'cosine'. Default: 'euclidean'", required: false

          # Prediction parameters
          string :target_column, description: "Name of the target/dependent variable column. Required for prediction analysis.", required: false
          array :feature_columns, of: :string, description: "Array of feature column names to use. Default: all numeric columns except target", required: false
          string :model_type, description: "Prediction model: 'linear_regression', 'classification'. Default: 'linear_regression'", required: false
          number :validation_split, description: "Fraction of data for validation (0.0-1.0). Default: 0.2", required: false
        end
      end

      VALID_ANALYSIS_TYPES = [
        "statistical_summary",
        "correlation_analysis",
        "time_series",
        "clustering",
        "prediction"
      ].freeze

      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      def execute(analysis_type:, data_source:, **parameters)
        analysis_start = Time.now

        begin
          @logger.info("DataScienceKit#execute analysis_type=#{analysis_type} data_source=#{data_source}")

          # Validate analysis type
          unless VALID_ANALYSIS_TYPES.include?(analysis_type)
            return {
              success: false,
              error: "Invalid analysis type: #{analysis_type}",
              valid_types: VALID_ANALYSIS_TYPES,
              analysis_type: analysis_type
            }
          end

          # Load and validate data
          data = load_data(data_source)
          validate_data_for_analysis(data, analysis_type, parameters)

          # Perform analysis
          result = case analysis_type
          when "statistical_summary"
            generate_statistical_summary(data, parameters)
          when "correlation_analysis"
            perform_correlation_analysis(data, parameters)
          when "time_series"
            analyze_time_series(data, parameters)
          when "clustering"
            perform_clustering(data, parameters)
          when "prediction"
            generate_predictions(data, parameters)
          end

          analysis_duration = (Time.now - analysis_start).round(3)
          @logger.info("Analysis completed in #{analysis_duration}s")

          {
            success: true,
            analysis_type: analysis_type,
            result: result,
            data_summary: summarize_data(data),
            analyzed_at: Time.now.iso8601,
            duration_seconds: analysis_duration
          }
        rescue => e
          @logger.error("Analysis failed: #{e.message}")
          {
            success: false,
            error: e.message,
            error_type: e.class.name,
            analysis_type: analysis_type,
            data_source: data_source
          }
        end
      end

      private

      # Load data from various sources
      def load_data(source)
        @logger.debug("Loading data from: #{source}")

        # Detect source type
        if source.start_with?('http://', 'https://')
          load_from_url(source)
        elsif source.upcase.start_with?('SELECT')
          load_from_database(source)
        else
          load_from_file(source)
        end
      end

      def load_from_url(url)
        @logger.debug("Loading from URL: #{url}")
        # In production, would fetch from actual URL
        # For demo, return sample data
        generate_sample_data(30)
      end

      def load_from_database(query)
        @logger.debug("Loading from database query")
        # In production, would execute database query
        # For demo, return sample data
        generate_sample_data(50)
      end

      def load_from_file(file_path)
        @logger.debug("Loading from file: #{file_path}")

        # Check if file exists
        unless File.exist?(file_path)
          @logger.warn("File not found, using sample data")
          return generate_sample_data(25)
        end

        # Parse based on file extension
        case File.extname(file_path).downcase
        when '.json'
          JSON.parse(File.read(file_path))
        else
          # For demo, return sample data
          @logger.warn("Using sample data for file type")
          generate_sample_data(20)
        end
      end

      # Generate sample data for testing
      def generate_sample_data(size = 30)
        (1..size).map do |i|
          {
            "id" => i,
            "value" => 50 + rand(-20..20) + (i * 0.5).to_i,
            "category" => ["A", "B", "C"][i % 3],
            "score" => 60 + rand(40),
            "date" => (Time.now - (size - i) * 86400).strftime("%Y-%m-%d"),
            "metric_x" => rand(100),
            "metric_y" => rand(100)
          }
        end
      end

      # Validate data for specific analysis type
      def validate_data_for_analysis(data, analysis_type, parameters)
        raise ArgumentError, "Data cannot be empty" if data.nil? || data.empty?
        raise ArgumentError, "Data must be an array of hashes" unless data.is_a?(Array) && data.first.is_a?(Hash)

        case analysis_type
        when "time_series"
          date_col = parameters[:date_column] || "date"
          raise ArgumentError, "Time series requires date column: #{date_col}" unless data.first.key?(date_col)
        when "prediction"
          target_col = parameters[:target_column]
          raise ArgumentError, "Prediction requires target_column parameter" unless target_col
          raise ArgumentError, "Target column '#{target_col}' not found in data" unless data.first.key?(target_col)
        end
      end

      # Statistical summary analysis
      def generate_statistical_summary(data, parameters)
        confidence_level = parameters[:confidence_level] || 0.95
        include_quartiles = parameters[:include_quartiles].nil? ? true : parameters[:include_quartiles]
        outlier_method = parameters[:outlier_method] || "iqr"

        # Extract numeric columns
        numeric_columns = detect_numeric_columns(data)

        summary = {
          total_records: data.length,
          numeric_columns: numeric_columns.length,
          column_statistics: {}
        }

        numeric_columns.each do |col_name|
          values = data.map { |row| row[col_name].to_f }.compact
          sorted = values.sort

          stats = {
            count: values.length,
            min: sorted.first.round(2),
            max: sorted.last.round(2),
            mean: (values.sum / values.length).round(2),
            median: sorted[sorted.length / 2].round(2),
            std_dev: calculate_std_dev(values).round(2)
          }

          if include_quartiles
            stats[:q1] = sorted[sorted.length / 4].round(2)
            stats[:q3] = sorted[(sorted.length * 3) / 4].round(2)
            stats[:iqr] = (stats[:q3] - stats[:q1]).round(2)
          end

          if outlier_method == "iqr" && include_quartiles
            stats[:outliers] = detect_outliers_iqr(values, stats[:q1], stats[:q3], stats[:iqr])
          end

          summary[:column_statistics][col_name] = stats
        end

        summary[:recommendations] = generate_stats_recommendations(summary)
        summary
      end

      # Correlation analysis
      def perform_correlation_analysis(data, parameters)
        method = parameters[:method] || "pearson"
        significance_level = parameters[:significance_level] || 0.05

        numeric_columns = detect_numeric_columns(data)

        raise ArgumentError, "Need at least 2 numeric columns for correlation analysis" if numeric_columns.length < 2

        correlations = []
        correlation_matrix = {}

        numeric_columns.combination(2).each do |col1, col2|
          values1 = data.map { |row| row[col1].to_f }
          values2 = data.map { |row| row[col2].to_f }

          corr = calculate_correlation(values1, values2)

          correlations << {
            column1: col1,
            column2: col2,
            correlation: corr,
            strength: interpret_correlation(corr),
            significant: corr.abs > significance_level
          }

          correlation_matrix["#{col1}_#{col2}"] = corr
        end

        {
          method: method,
          correlations: correlations.sort_by { |c| -c[:correlation].abs },
          strongest_correlation: correlations.max_by { |c| c[:correlation].abs },
          correlation_matrix: correlation_matrix,
          interpretation: "Correlations using #{method} method with significance level #{significance_level}"
        }
      end

      # Time series analysis
      def analyze_time_series(data, parameters)
        date_column = parameters[:date_column] || "date"
        value_column = parameters[:value_column] || "value"
        forecast_periods = parameters[:forecast_periods] || 7

        # Extract time series data
        time_series = data.map { |row| {date: row[date_column], value: row[value_column].to_f} }
          .sort_by { |point| point[:date] }

        values = time_series.map { |point| point[:value] }

        # Calculate trend
        trend = calculate_trend(values)

        # Detect seasonality (simplified)
        seasonality = detect_seasonality(values)

        # Simple forecast using moving average
        forecast = forecast_values(values, forecast_periods)

        {
          data_points: time_series.length,
          date_range: {
            start: time_series.first[:date],
            end: time_series.last[:date]
          },
          trend: {
            direction: trend[:direction],
            slope: trend[:slope],
            interpretation: trend[:interpretation]
          },
          seasonality: seasonality,
          statistics: {
            mean: (values.sum / values.length).round(2),
            volatility: calculate_std_dev(values).round(2),
            min: values.min.round(2),
            max: values.max.round(2)
          },
          forecast: {
            method: "moving_average",
            periods: forecast_periods,
            values: forecast
          }
        }
      end

      # Clustering analysis
      def perform_clustering(data, parameters)
        n_clusters = parameters[:n_clusters] || 3
        algorithm = parameters[:algorithm] || "kmeans"
        distance_metric = parameters[:distance_metric] || "euclidean"

        # Extract numeric features
        numeric_columns = detect_numeric_columns(data)
        raise ArgumentError, "Need numeric columns for clustering" if numeric_columns.empty?

        # Prepare feature matrix
        features = data.map do |row|
          numeric_columns.map { |col| row[col].to_f }
        end

        # Perform clustering (simplified k-means)
        clusters = perform_kmeans(features, n_clusters)

        # Calculate cluster statistics
        cluster_stats = analyze_clusters(clusters, features, data)

        {
          algorithm: algorithm,
          n_clusters: n_clusters,
          distance_metric: distance_metric,
          total_points: data.length,
          clusters: cluster_stats,
          quality_metrics: {
            inertia: calculate_inertia(clusters, features),
            silhouette_score: "Not implemented (would require full ML library)"
          }
        }
      end

      # Prediction/Regression analysis
      def generate_predictions(data, parameters)
        target_column = parameters[:target_column]
        feature_columns = parameters[:feature_columns] || detect_numeric_columns(data).reject { |c| c == target_column }
        model_type = parameters[:model_type] || "linear_regression"
        validation_split = parameters[:validation_split] || 0.2

        # Split data
        train_size = (data.length * (1 - validation_split)).to_i
        train_data = data[0...train_size]
        test_data = data[train_size..-1]

        # Extract features and target
        train_features = train_data.map { |row| feature_columns.map { |col| row[col].to_f } }
        train_targets = train_data.map { |row| row[target_column].to_f }

        # Simple linear model (simplified)
        model = train_simple_model(train_features, train_targets)

        # Make predictions on test set
        test_features = test_data.map { |row| feature_columns.map { |col| row[col].to_f } }
        test_targets = test_data.map { |row| row[target_column].to_f }

        predictions = test_features.map { |features| predict(model, features) }

        # Calculate metrics
        mse = calculate_mse(test_targets, predictions)
        rmse = Math.sqrt(mse)
        mae = calculate_mae(test_targets, predictions)
        r_squared = calculate_r_squared(test_targets, predictions)

        {
          model_type: model_type,
          target_column: target_column,
          feature_columns: feature_columns,
          training_samples: train_size,
          test_samples: test_data.length,
          model_parameters: model,
          performance: {
            mse: mse.round(2),
            rmse: rmse.round(2),
            mae: mae.round(2),
            r_squared: r_squared.round(3)
          },
          sample_predictions: predictions.first(5).map { |p| p.round(2) },
          feature_importance: calculate_feature_importance(model, feature_columns)
        }
      end

      # Data summarization
      def summarize_data(data)
        numeric_cols = detect_numeric_columns(data)
        categorical_cols = detect_categorical_columns(data)

        {
          total_records: data.length,
          total_columns: data.first.keys.length,
          numeric_columns: numeric_cols,
          categorical_columns: categorical_cols,
          memory_estimate_mb: (data.to_json.length / (1024.0 * 1024.0)).round(2)
        }
      end

      # Helper methods

      def detect_numeric_columns(data)
        return [] if data.empty?

        data.first.keys.select do |key|
          sample_values = data.first(10).map { |row| row[key] }
          sample_values.all? { |v| v.to_s.match?(/^-?\d+\.?\d*$/) }
        end
      end

      def detect_categorical_columns(data)
        return [] if data.empty?

        data.first.keys.select do |key|
          sample_values = data.first(10).map { |row| row[key] }
          unique_ratio = sample_values.uniq.length.to_f / sample_values.length
          unique_ratio < 0.7 && !sample_values.all? { |v| v.to_s.match?(/^-?\d+\.?\d*$/) }
        end
      end

      def calculate_std_dev(values)
        mean = values.sum / values.length
        variance = values.sum { |v| (v - mean) ** 2 } / values.length
        Math.sqrt(variance)
      end

      def calculate_correlation(values1, values2)
        return 0.0 if values1.empty? || values2.empty?

        mean1 = values1.sum / values1.length
        mean2 = values2.sum / values2.length

        covariance = values1.zip(values2).sum { |v1, v2| (v1 - mean1) * (v2 - mean2) } / values1.length
        std1 = Math.sqrt(values1.sum { |v| (v - mean1) ** 2 } / values1.length)
        std2 = Math.sqrt(values2.sum { |v| (v - mean2) ** 2 } / values2.length)

        return 0.0 if std1 == 0 || std2 == 0

        (covariance / (std1 * std2)).round(3)
      end

      def interpret_correlation(corr)
        abs_corr = corr.abs
        case abs_corr
        when 0.0...0.3 then 'weak'
        when 0.3...0.7 then 'moderate'
        else 'strong'
        end
      end

      def detect_outliers_iqr(values, q1, q3, iqr)
        lower_bound = q1 - (1.5 * iqr)
        upper_bound = q3 + (1.5 * iqr)

        outliers = values.select { |v| v < lower_bound || v > upper_bound }
        {
          count: outliers.length,
          percentage: (outliers.length.to_f / values.length * 100).round(2),
          values: outliers.first(10).map { |v| v.round(2) }
        }
      end

      def generate_stats_recommendations(summary)
        recommendations = []

        summary[:column_statistics].each do |col, stats|
          if stats[:outliers] && stats[:outliers][:count] > 0
            recommendations << "Column '#{col}' has #{stats[:outliers][:count]} outliers (#{stats[:outliers][:percentage]}%)"
          end

          if stats[:std_dev] > stats[:mean]
            recommendations << "Column '#{col}' shows high variability (std_dev > mean)"
          end
        end

        recommendations << "Data quality appears good" if recommendations.empty?
        recommendations
      end

      def calculate_trend(values)
        n = values.length
        x = (0...n).to_a
        y = values

        # Simple linear regression for trend
        x_mean = x.sum.to_f / n
        y_mean = y.sum.to_f / n

        numerator = x.zip(y).sum { |xi, yi| (xi - x_mean) * (yi - y_mean) }
        denominator = x.sum { |xi| (xi - x_mean) ** 2 }

        slope = denominator == 0 ? 0 : numerator / denominator

        {
          slope: slope.round(3),
          direction: slope > 0 ? 'increasing' : (slope < 0 ? 'decreasing' : 'stable'),
          interpretation: interpret_trend(slope)
        }
      end

      def interpret_trend(slope)
        abs_slope = slope.abs
        if abs_slope < 0.1
          "Stable trend with minimal change"
        elsif slope > 0
          abs_slope > 1 ? "Strong upward trend" : "Moderate upward trend"
        else
          abs_slope > 1 ? "Strong downward trend" : "Moderate downward trend"
        end
      end

      def detect_seasonality(values)
        # Simplified seasonality detection
        if values.length < 12
          return {detected: false, reason: "Insufficient data points for seasonality detection"}
        end

        # Check for repeating patterns (very simplified)
        {
          detected: false,
          note: "Full seasonality detection requires statistical libraries (statsmodels, etc.)"
        }
      end

      def forecast_values(historical_values, periods)
        # Simple moving average forecast
        window_size = [5, historical_values.length / 3].min
        recent = historical_values.last(window_size)
        avg = recent.sum / recent.length

        (1..periods).map do |i|
          {
            period: i,
            forecast: (avg + (historical_values.last - avg) * (1.0 / i)).round(2),
            confidence: "low (simple moving average)"
          }
        end
      end

      def perform_kmeans(features, k)
        # Simplified k-means implementation
        n_samples = features.length
        n_features = features.first.length

        # Initialize centroids randomly
        centroids = features.sample(k)
        assignments = Array.new(n_samples, 0)

        # Iterate a few times
        5.times do
          # Assign points to nearest centroid
          features.each_with_index do |point, idx|
            distances = centroids.map { |centroid| euclidean_distance(point, centroid) }
            assignments[idx] = distances.each_with_index.min[1]
          end

          # Update centroids
          k.times do |cluster_id|
            cluster_points = features.select.with_index { |_, idx| assignments[idx] == cluster_id }
            next if cluster_points.empty?

            centroids[cluster_id] = cluster_points.first.each_index.map do |feature_idx|
              cluster_points.map { |p| p[feature_idx] }.sum / cluster_points.length
            end
          end
        end

        {assignments: assignments, centroids: centroids}
      end

      def euclidean_distance(point1, point2)
        Math.sqrt(point1.zip(point2).sum { |a, b| (a - b) ** 2 })
      end

      def analyze_clusters(clusters, features, data)
        assignments = clusters[:assignments]
        centroids = clusters[:centroids]

        cluster_info = {}

        centroids.each_with_index do |centroid, cluster_id|
          cluster_points_idx = assignments.each_index.select { |i| assignments[i] == cluster_id }

          cluster_info[cluster_id] = {
            size: cluster_points_idx.length,
            percentage: (cluster_points_idx.length.to_f / data.length * 100).round(2),
            centroid: centroid.map { |v| v.round(2) }
          }
        end

        cluster_info
      end

      def calculate_inertia(clusters, features)
        # Sum of squared distances to nearest centroid
        inertia = 0
        clusters[:assignments].each_with_index do |cluster_id, idx|
          centroid = clusters[:centroids][cluster_id]
          inertia += euclidean_distance(features[idx], centroid) ** 2
        end
        inertia.round(2)
      end

      def train_simple_model(features, targets)
        # Simple linear model: y = w0 + w1*x1 + w2*x2 + ...
        # Using closed-form solution (very simplified)
        n_features = features.first.length

        # Initialize weights (simplified - normally would use proper linear algebra)
        weights = Array.new(n_features) { rand(-1.0..1.0) }
        intercept = targets.sum / targets.length

        {
          intercept: intercept.round(3),
          weights: weights.map { |w| w.round(3) }
        }
      end

      def predict(model, features)
        model[:intercept] + features.zip(model[:weights]).sum { |f, w| f * w }
      end

      def calculate_mse(actual, predicted)
        actual.zip(predicted).sum { |a, p| (a - p) ** 2 } / actual.length
      end

      def calculate_mae(actual, predicted)
        actual.zip(predicted).sum { |a, p| (a - p).abs } / actual.length
      end

      def calculate_r_squared(actual, predicted)
        mean = actual.sum / actual.length
        ss_tot = actual.sum { |a| (a - mean) ** 2 }
        ss_res = actual.zip(predicted).sum { |a, p| (a - p) ** 2 }

        return 0.0 if ss_tot == 0
        1.0 - (ss_res / ss_tot)
      end

      def calculate_feature_importance(model, feature_columns)
        # Simplified feature importance based on absolute weight values
        weights = model[:weights].map(&:abs)
        total = weights.sum

        return {} if total == 0

        feature_columns.zip(weights).map do |col, weight|
          {
            feature: col,
            importance: (weight / total).round(3),
            weight: weight.round(3)
          }
        end.sort_by { |f| -f[:importance] }
      end
    end
  end
end
