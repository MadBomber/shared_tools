# lib/shared_tools/mcp/tool_schema_patch.rb
#
# Patch: strip JSON Schema meta-fields from MCP tool input schemas before
# they are sent to the LLM provider API.
#
# Some MCP servers (e.g. @playwright/mcp) annotate their inputSchema with
# "$schema": "https://json-schema.org/draft/2020-12/schema" (Draft 2020-12).
# Claude's API does not accept the "$schema" key in tool definitions and
# responds with a 400 BadRequestError when it is present.
#
# ruby_llm-mcp already strips "$schema" from output schemas before validation
# (tool.rb line 78) but does not strip it from the normalized_input_schema
# returned by params_schema, which is what gets serialized into the API request.
#
# This patch overrides params_schema to remove "$schema" (and any other
# unsupported meta-fields) before the schema is sent upstream.  The strip is
# applied recursively so nested object/array sub-schemas are also cleaned.
#
# Safe because:
#   - "$schema" is purely a declaration of which JSON Schema draft is used;
#     it carries no semantic meaning for tool parameter validation by the LLM.
#   - The original @normalized_input_schema is not mutated; a new Hash is
#     returned each time, leaving internal state intact.

require "ruby_llm/mcp"

module RubyLLM
  module MCP
    class Tool
      # Keys that Claude's API does not accept in tool input schemas.
      UNSUPPORTED_SCHEMA_KEYS = %w[$schema].freeze

      def params_schema
        sanitize_schema(@normalized_input_schema)
      end

      private

      def sanitize_schema(schema)
        return schema unless schema.is_a?(Hash)

        schema
          .reject { |k, _| UNSUPPORTED_SCHEMA_KEYS.include?(k) }
          .transform_values { |v| sanitize_schema_value(v) }
      end

      def sanitize_schema_value(value)
        case value
        when Hash  then sanitize_schema(value)
        when Array then value.map { |item| sanitize_schema_value(item) }
        else            value
        end
      end
    end
  end
end
