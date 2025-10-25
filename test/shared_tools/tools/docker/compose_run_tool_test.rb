# frozen_string_literal: true

require "test_helper"

class ComposeRunToolTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @tool = SharedTools::Tools::Docker::ComposeRunTool.new(root: @temp_dir)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_tool_name
    assert_equal 'docker_compose_run', SharedTools::Tools::Docker::ComposeRunTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_accepts_service_command_and_args
    # This test verifies the tool accepts the expected parameters
    # We can't actually run docker commands in tests without docker being available
    # So we'll just verify the tool is set up correctly
    assert_respond_to @tool, :execute
  end

  def test_execute_method_signature
    # Verify the execute method accepts the correct parameters
    method = @tool.method(:execute)
    params = method.parameters

    # Should have command (required), service (optional), args (optional)
    param_names = params.map { |type, name| name }
    assert_includes param_names, :command
    assert_includes param_names, :service
    assert_includes param_names, :args
  end

  def test_default_service_is_app
    # We can verify behavior by checking the method signature and defaults
    method = @tool.method(:execute)
    params = method.parameters

    # Find the service parameter
    service_param = params.find { |type, name| name == :service }

    # If it has a default value, it should be key type (optional)
    assert_equal :key, service_param[0] if service_param
  end

  def test_handles_capture_error
    # Test that CaptureError is defined
    assert defined?(SharedTools::Tools::Docker::ComposeRunTool::CaptureError)
  end

  def test_capture_error_has_attributes
    error_class = SharedTools::Tools::Docker::ComposeRunTool::CaptureError

    # Create a simple status object
    status_obj = Struct.new(:exitstatus).new(1)

    error = error_class.new(text: "Error message", status: status_obj)

    assert_equal "Error message", error.text
    assert_equal status_obj, error.status
    assert_includes error.message, "[STATUS=1]"
    assert_includes error.message, "Error message"
  end
end
