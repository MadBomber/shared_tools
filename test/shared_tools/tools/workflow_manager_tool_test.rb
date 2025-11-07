# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"

class WorkflowManagerToolTest < Minitest::Test
  def setup
    # Use temporary directory for workflow storage
    @temp_dir = Dir.mktmpdir("workflow_test")
    @tool = SharedTools::Tools::WorkflowManagerTool.new(storage_dir: @temp_dir)
  end

  def teardown
    # Clean up temporary directory
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
  end

  def test_tool_name
    assert_equal 'workflow_manager', SharedTools::Tools::WorkflowManagerTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  # Start workflow tests
  def test_start_workflow_success
    result = @tool.execute(
      action: "start",
      step_data: {name: "test_workflow", type: "demo"}
    )

    assert result[:success]
    assert result[:workflow_id]
    assert_equal "started", result[:status]
    assert result[:created_at]
    assert result[:next_actions]
    assert result[:next_actions].is_a?(Array)
  end

  def test_start_workflow_generates_unique_ids
    result1 = @tool.execute(action: "start", step_data: {})
    result2 = @tool.execute(action: "start", step_data: {})

    assert result1[:success]
    assert result2[:success]
    refute_equal result1[:workflow_id], result2[:workflow_id]
  end

  def test_start_workflow_with_empty_data
    result = @tool.execute(action: "start", step_data: {})

    assert result[:success]
    assert result[:workflow_id]
  end

  def test_start_workflow_with_complex_data
    result = @tool.execute(
      action: "start",
      step_data: {
        name: "complex_workflow",
        config: {timeout: 300, retry: true},
        items: ["item1", "item2", "item3"]
      }
    )

    assert result[:success]
    assert result[:workflow_id]
  end

  # Step execution tests
  def test_execute_workflow_step_success
    # Start workflow
    start_result = @tool.execute(action: "start", step_data: {})
    workflow_id = start_result[:workflow_id]

    # Execute step
    step_result = @tool.execute(
      action: "step",
      workflow_id: workflow_id,
      step_data: {action: "process", value: 42}
    )

    assert step_result[:success]
    assert_equal workflow_id, step_result[:workflow_id]
    assert_equal 1, step_result[:step_number]
    assert step_result[:step_result]
    assert_equal "active", step_result[:workflow_status]
    assert_equal 1, step_result[:total_steps]
  end

  def test_execute_multiple_workflow_steps
    # Start workflow
    start_result = @tool.execute(action: "start", step_data: {})
    workflow_id = start_result[:workflow_id]

    # Execute multiple steps
    3.times do |i|
      step_result = @tool.execute(
        action: "step",
        workflow_id: workflow_id,
        step_data: {step: i + 1}
      )

      assert step_result[:success]
      assert_equal i + 1, step_result[:step_number]
      assert_equal i + 1, step_result[:total_steps]
    end
  end

  def test_step_without_workflow_id
    result = @tool.execute(
      action: "step",
      step_data: {action: "test"}
    )

    refute result[:success]
    assert_includes result[:error], "workflow_id required"
  end

  def test_step_with_invalid_workflow_id
    result = @tool.execute(
      action: "step",
      workflow_id: "invalid-uuid-123",
      step_data: {action: "test"}
    )

    refute result[:success]
    assert_includes result[:error], "not found"
  end

  def test_cannot_add_step_to_completed_workflow
    # Start and complete workflow
    start_result = @tool.execute(action: "start", step_data: {})
    workflow_id = start_result[:workflow_id]
    @tool.execute(action: "complete", workflow_id: workflow_id)

    # Try to add step
    result = @tool.execute(
      action: "step",
      workflow_id: workflow_id,
      step_data: {action: "test"}
    )

    refute result[:success]
    assert_includes result[:error], "completed workflow"
  end

  # Status check tests
  def test_get_workflow_status
    # Start workflow and add steps
    start_result = @tool.execute(action: "start", step_data: {initial: true})
    workflow_id = start_result[:workflow_id]

    @tool.execute(action: "step", workflow_id: workflow_id, step_data: {step: 1})
    @tool.execute(action: "step", workflow_id: workflow_id, step_data: {step: 2})

    # Get status
    status_result = @tool.execute(
      action: "status",
      workflow_id: workflow_id
    )

    assert status_result[:success]
    assert_equal workflow_id, status_result[:workflow_id]
    assert_equal "active", status_result[:status]
    assert_equal 2, status_result[:step_count]
    assert status_result[:steps]
    assert_equal 2, status_result[:steps].length
    assert status_result[:metadata]
    assert status_result[:next_actions]
  end

  def test_status_without_workflow_id
    result = @tool.execute(action: "status")

    refute result[:success]
    assert_includes result[:error], "workflow_id required"
  end

  def test_status_with_invalid_workflow_id
    result = @tool.execute(
      action: "status",
      workflow_id: "nonexistent-123"
    )

    refute result[:success]
    assert_includes result[:error], "not found"
  end

  def test_status_shows_step_details
    # Start workflow and add step
    start_result = @tool.execute(action: "start", step_data: {})
    workflow_id = start_result[:workflow_id]
    @tool.execute(action: "step", workflow_id: workflow_id, step_data: {test: true})

    # Get status
    status_result = @tool.execute(action: "status", workflow_id: workflow_id)

    assert status_result[:success]
    step = status_result[:steps].first
    assert_equal 1, step[:step_number]
    assert step[:processed_at]
    assert step[:has_result]
  end

  # Complete workflow tests
  def test_complete_workflow
    # Start workflow and add step
    start_result = @tool.execute(action: "start", step_data: {})
    workflow_id = start_result[:workflow_id]
    @tool.execute(action: "step", workflow_id: workflow_id, step_data: {final: true})

    # Complete workflow
    complete_result = @tool.execute(
      action: "complete",
      workflow_id: workflow_id
    )

    assert complete_result[:success]
    assert_equal workflow_id, complete_result[:workflow_id]
    assert_equal "completed", complete_result[:status]
    assert complete_result[:completed_at]
    assert_equal 1, complete_result[:total_steps]
    assert complete_result[:summary]
    assert complete_result[:summary][:duration_seconds]
  end

  def test_complete_without_workflow_id
    result = @tool.execute(action: "complete")

    refute result[:success]
    assert_includes result[:error], "workflow_id required"
  end

  def test_complete_invalid_workflow_id
    result = @tool.execute(
      action: "complete",
      workflow_id: "invalid-123"
    )

    refute result[:success]
    assert_includes result[:error], "not found"
  end

  def test_cannot_complete_already_completed_workflow
    # Start and complete workflow
    start_result = @tool.execute(action: "start", step_data: {})
    workflow_id = start_result[:workflow_id]
    @tool.execute(action: "complete", workflow_id: workflow_id)

    # Try to complete again
    result = @tool.execute(
      action: "complete",
      workflow_id: workflow_id
    )

    refute result[:success]
    assert_includes result[:error], "already completed"
  end

  # Workflow persistence tests
  def test_workflow_persists_across_tool_instances
    # Create workflow with first tool instance
    result = @tool.execute(action: "start", step_data: {persist: true})
    workflow_id = result[:workflow_id]
    @tool.execute(action: "step", workflow_id: workflow_id, step_data: {step: 1})

    # Create new tool instance with same storage dir
    new_tool = SharedTools::Tools::WorkflowManagerTool.new(storage_dir: @temp_dir)

    # Verify workflow is accessible
    status_result = new_tool.execute(action: "status", workflow_id: workflow_id)

    assert status_result[:success]
    assert_equal 1, status_result[:step_count]
  end

  def test_workflow_state_file_created
    result = @tool.execute(action: "start", step_data: {})
    workflow_id = result[:workflow_id]

    file_path = File.join(@temp_dir, "workflow_#{workflow_id}.json")
    assert File.exist?(file_path)
  end

  # Next actions tests
  def test_next_actions_suggest_step
    result = @tool.execute(action: "start", step_data: {})

    assert result[:next_actions]
    step_action = result[:next_actions].find { |a| a[:action] == "step" }
    assert step_action
    assert step_action[:description]
    assert step_action[:required_params]
  end

  def test_next_actions_suggest_complete_after_steps
    start_result = @tool.execute(action: "start", step_data: {})
    workflow_id = start_result[:workflow_id]
    @tool.execute(action: "step", workflow_id: workflow_id, step_data: {})

    status_result = @tool.execute(action: "status", workflow_id: workflow_id)

    complete_action = status_result[:next_actions].find { |a| a[:action] == "complete" }
    assert complete_action
  end

  def test_no_next_actions_for_completed_workflow
    start_result = @tool.execute(action: "start", step_data: {})
    workflow_id = start_result[:workflow_id]
    @tool.execute(action: "complete", workflow_id: workflow_id)

    status_result = @tool.execute(action: "status", workflow_id: workflow_id)

    assert status_result[:next_actions]
    assert_empty status_result[:next_actions]
  end

  # Invalid action tests
  def test_invalid_action
    result = @tool.execute(action: "invalid_action")

    refute result[:success]
    assert_includes result[:error], "Unknown action"
  end

  # Metadata tests
  def test_workflow_includes_metadata
    start_result = @tool.execute(action: "start", step_data: {})
    workflow_id = start_result[:workflow_id]
    @tool.execute(action: "step", workflow_id: workflow_id, step_data: {})

    status_result = @tool.execute(action: "status", workflow_id: workflow_id)

    assert status_result[:metadata]
    assert_equal 1, status_result[:metadata][:step_count]
    assert status_result[:metadata][:last_step_at]
  end

  def test_workflow_tracks_timestamps
    start_result = @tool.execute(action: "start", step_data: {})

    assert start_result[:created_at]
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, start_result[:created_at])
  end

  # Full workflow lifecycle test
  def test_complete_workflow_lifecycle
    # 1. Start
    start_result = @tool.execute(action: "start", step_data: {workflow: "test"})
    assert start_result[:success]
    workflow_id = start_result[:workflow_id]

    # 2. Add steps
    3.times do |i|
      step_result = @tool.execute(
        action: "step",
        workflow_id: workflow_id,
        step_data: {step_number: i + 1}
      )
      assert step_result[:success]
    end

    # 3. Check status
    status_result = @tool.execute(action: "status", workflow_id: workflow_id)
    assert status_result[:success]
    assert_equal 3, status_result[:step_count]
    assert_equal "active", status_result[:status]

    # 4. Complete
    complete_result = @tool.execute(action: "complete", workflow_id: workflow_id)
    assert complete_result[:success]
    assert_equal "completed", complete_result[:status]

    # 5. Verify completed status
    final_status = @tool.execute(action: "status", workflow_id: workflow_id)
    assert final_status[:success]
    assert_equal "completed", final_status[:status]
  end
end
