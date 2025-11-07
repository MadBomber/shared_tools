# workflow_manager_tool.rb - Managing state across tool invocations
require 'ruby_llm/tool'
require 'securerandom'
require 'json'
require 'fileutils'

module SharedTools
  module Tools
    class WorkflowManagerTool < RubyLLM::Tool
      def self.name = 'workflow_manager'

      description <<~'DESCRIPTION'
        Manage complex multi-step workflows with persistent state tracking across tool invocations.
        This tool enables the creation and management of stateful workflows that can span multiple
        AI interactions and tool calls. It provides workflow initialization, step-by-step execution,
        status monitoring, and completion tracking. Each workflow maintains its state in persistent
        storage, allowing for resumption of long-running processes and coordination between
        multiple tools and AI interactions. Perfect for complex automation tasks that require
        multiple stages and decision points.

        Workflow lifecycle:
        1. Start: Initialize a new workflow with initial data (returns workflow_id)
        2. Step: Execute multiple workflow steps using the workflow_id
        3. Status: Check workflow progress and state at any time
        4. Complete: Finalize the workflow and clean up resources

        All workflow state is persisted to disk and can survive process restarts.
      DESCRIPTION

      params do
        string :action, description: <<~DESC.strip
          Workflow management action to perform:
          - 'start': Initialize a new workflow with initial data and return workflow ID
          - 'step': Execute the next step in an existing workflow using provided step data
          - 'status': Check the current status and progress of an existing workflow
          - 'complete': Mark a workflow as finished and clean up associated resources
          Each action requires different combinations of the other parameters.
        DESC

        string :workflow_id, description: <<~DESC.strip, required: false
          Unique identifier for an existing workflow. Required for 'step', 'status', and 'complete'
          actions. This ID is returned when starting a new workflow and should be used for all
          subsequent operations on that workflow. The ID is a UUID string that ensures
          uniqueness across all workflow instances.
        DESC

        object :step_data, description: <<~DESC.strip, required: false
          Hash containing data and parameters specific to the current workflow step.
          For 'start' action: Initial configuration and parameters for the workflow.
          For 'step' action: Input data, parameters, and context needed for the next step.
          The structure depends on the specific workflow type and current step requirements.
          Can include nested hashes, arrays, and any JSON-serializable data types.
        DESC
      end

      def initialize(logger: nil, storage_dir: nil)
        @logger = logger || RubyLLM.logger
        @storage_dir = storage_dir || ".workflows"
        FileUtils.mkdir_p(@storage_dir) unless Dir.exist?(@storage_dir)
      end

      def execute(action:, workflow_id: nil, step_data: {})
        @logger.info("WorkflowManagerTool#execute action=#{action} workflow_id=#{workflow_id}")

        case action
        when "start"
          start_workflow(step_data)
        when "step"
          return {success: false, error: "workflow_id required for 'step' action"} unless workflow_id
          process_workflow_step(workflow_id, step_data)
        when "status"
          return {success: false, error: "workflow_id required for 'status' action"} unless workflow_id
          get_workflow_status(workflow_id)
        when "complete"
          return {success: false, error: "workflow_id required for 'complete' action"} unless workflow_id
          complete_workflow(workflow_id)
        else
          {success: false, error: "Unknown action: #{action}"}
        end
      rescue => e
        @logger.error("Workflow operation failed: #{e.message}")
        {
          success: false,
          error: "Workflow operation failed: #{e.message}",
          error_type: e.class.name
        }
      end

      private

      # Start a new workflow
      def start_workflow(initial_data)
        workflow_id = SecureRandom.uuid
        workflow_state = {
          id: workflow_id,
          status: "active",
          steps: [],
          created_at: Time.now.iso8601,
          updated_at: Time.now.iso8601,
          data: initial_data,
          metadata: {
            step_count: 0,
            last_step_at: nil
          }
        }

        save_workflow_state(workflow_id, workflow_state)
        @logger.info("Workflow started: #{workflow_id}")

        {
          success: true,
          workflow_id: workflow_id,
          status: "started",
          created_at: workflow_state[:created_at],
          next_actions: suggested_next_actions(workflow_state)
        }
      end

      # Process a workflow step
      def process_workflow_step(workflow_id, step_data)
        workflow_state = load_workflow_state(workflow_id)
        return {success: false, error: "Workflow not found: #{workflow_id}"} unless workflow_state

        if workflow_state[:status] == "completed"
          return {success: false, error: "Cannot add steps to completed workflow"}
        end

        step_number = workflow_state[:steps].length + 1
        step_result = process_step_logic(step_data, workflow_state)

        step = {
          step_number: step_number,
          data: step_data,
          result: step_result,
          processed_at: Time.now.iso8601,
          execution_time_seconds: 0.001  # Placeholder
        }

        workflow_state[:steps] << step
        workflow_state[:updated_at] = Time.now.iso8601
        workflow_state[:metadata][:step_count] = step_number
        workflow_state[:metadata][:last_step_at] = step[:processed_at]

        save_workflow_state(workflow_id, workflow_state)
        @logger.info("Workflow step #{step_number} completed: #{workflow_id}")

        {
          success: true,
          workflow_id: workflow_id,
          step_number: step_number,
          step_result: step_result,
          workflow_status: workflow_state[:status],
          total_steps: step_number,
          next_actions: suggested_next_actions(workflow_state)
        }
      end

      # Get workflow status
      def get_workflow_status(workflow_id)
        workflow_state = load_workflow_state(workflow_id)
        return {success: false, error: "Workflow not found: #{workflow_id}"} unless workflow_state

        @logger.debug("Workflow status retrieved: #{workflow_id}")

        {
          success: true,
          workflow_id: workflow_id,
          status: workflow_state[:status],
          created_at: workflow_state[:created_at],
          updated_at: workflow_state[:updated_at],
          step_count: workflow_state[:steps].length,
          steps: workflow_state[:steps].map { |step|
            {
              step_number: step[:step_number],
              processed_at: step[:processed_at],
              has_result: !step[:result].nil?
            }
          },
          metadata: workflow_state[:metadata],
          next_actions: suggested_next_actions(workflow_state)
        }
      end

      # Complete a workflow
      def complete_workflow(workflow_id)
        workflow_state = load_workflow_state(workflow_id)
        return {success: false, error: "Workflow not found: #{workflow_id}"} unless workflow_state

        if workflow_state[:status] == "completed"
          return {success: false, error: "Workflow already completed"}
        end

        workflow_state[:status] = "completed"
        workflow_state[:completed_at] = Time.now.iso8601
        workflow_state[:updated_at] = Time.now.iso8601

        save_workflow_state(workflow_id, workflow_state)
        @logger.info("Workflow completed: #{workflow_id}")

        {
          success: true,
          workflow_id: workflow_id,
          status: "completed",
          completed_at: workflow_state[:completed_at],
          total_steps: workflow_state[:steps].length,
          summary: {
            created_at: workflow_state[:created_at],
            completed_at: workflow_state[:completed_at],
            total_steps: workflow_state[:steps].length,
            duration_seconds: calculate_duration(workflow_state)
          }
        }
      end

      # Calculate workflow duration
      def calculate_duration(workflow_state)
        return 0 unless workflow_state[:completed_at] && workflow_state[:created_at]

        completed = Time.parse(workflow_state[:completed_at])
        created = Time.parse(workflow_state[:created_at])
        (completed - created).round(2)
      end

      # Suggest next actions based on workflow state
      def suggested_next_actions(workflow_state)
        return [] if workflow_state[:status] == "completed"

        actions = []

        # Always suggest adding a step
        actions << {
          action: "step",
          description: "Add the next workflow step",
          required_params: ["workflow_id", "step_data"]
        }

        # Suggest status check
        actions << {
          action: "status",
          description: "Check workflow progress and status",
          required_params: ["workflow_id"]
        }

        # Suggest completion if workflow has steps
        if workflow_state[:steps].length > 0
          actions << {
            action: "complete",
            description: "Mark workflow as complete",
            required_params: ["workflow_id"]
          }
        end

        actions
      end

      # Process individual step logic
      def process_step_logic(step_data, workflow_state)
        # This is a demonstration - in production, this would contain
        # actual business logic for processing workflow steps

        {
          processed: true,
          input_keys: step_data.keys,
          workflow_context: {
            current_step: workflow_state[:steps].length + 1,
            total_steps_so_far: workflow_state[:steps].length
          },
          timestamp: Time.now.iso8601
        }
      end

      # Save workflow state to disk
      def save_workflow_state(workflow_id, state)
        file_path = workflow_file_path(workflow_id)
        File.write(file_path, JSON.pretty_generate(state))
        @logger.debug("Workflow state saved: #{file_path}")
      rescue => e
        @logger.error("Failed to save workflow state: #{e.message}")
        raise
      end

      # Load workflow state from disk
      def load_workflow_state(workflow_id)
        file_path = workflow_file_path(workflow_id)
        return nil unless File.exist?(file_path)

        JSON.parse(File.read(file_path), symbolize_names: true)
      rescue => e
        @logger.error("Failed to load workflow state: #{e.message}")
        nil
      end

      # Get workflow file path
      def workflow_file_path(workflow_id)
        File.join(@storage_dir, "workflow_#{workflow_id}.json")
      end

      # Get storage directory (for testing)
      attr_reader :storage_dir
    end
  end
end
