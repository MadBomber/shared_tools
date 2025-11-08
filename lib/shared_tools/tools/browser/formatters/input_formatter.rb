# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      module Formatters
        # Handles formatting of input elements
        module InputFormatter
        module_function

          def format_input_field(input, indent = "")
            result = format_basic_line(input, indent)
            result += format_selectors_line(input, indent)
            result
          end

          def format_basic_line(input, indent)
            result = "#{indent}• #{input_type_display(input)}"
            result += input_id_display(input)
            result += input_value_display(input)
            result += input_placeholder_display(input)
            "#{result}\n"
          end

          def format_selectors_line(input, indent)
            selectors = SelectorGenerator.generate_stable_selectors(input)
            return "" if selectors.empty?

            format_selector_list(selectors, indent)
          end

          def format_selector_list(selectors, indent)
            result = "#{indent}  Stable selectors:\n"
            selectors.each { |sel| result += "#{indent}    - #{sel}\n" }
            "#{result}\n"
          end

          def input_type_display(input)
            (input["type"] || input.name).capitalize
          end

          def input_id_display(input)
            input["id"] ? " (#{input['id']})" : ""
          end

          def input_value_display(input)
            value = input["value"]
            value && !value.empty? ? " = '#{value}'" : ""
          end

          def input_placeholder_display(input)
            placeholder = input["placeholder"]
            placeholder && !placeholder.empty? ? " [#{placeholder}]" : ""
          end
        end
      end
    end
  end
end
