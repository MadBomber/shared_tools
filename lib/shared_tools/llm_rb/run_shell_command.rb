# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools
  verify_gem :llm_rb

  RunShellCommand = LLM.function(:system) do |fn|
    fn.description "Run a shell command"

    fn.params do |schema|
      schema.object(command: schema.string.required)
    end

    fn.define do |params|
      ro, wo = IO.pipe
      re, we = IO.pipe
      Process.wait Process.spawn(params.command, out: wo, err: we)
      [wo, we].each(&:close)
      { stderr: re.read, stdout: ro.read }
    end
  end
end
