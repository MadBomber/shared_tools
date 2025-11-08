# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      module Formatters
        # Formats grouped elements for optimal data entry display
        module DataEntryFormatter
        module_function

          def format_groups(grouped_elements, total_count, text)
            result = build_header(total_count, text)
            result += format_each_group(grouped_elements)
            result
          end

          def format_inputs(inputs)
            result = "📝 Data Entry Fields:\n"
            table_groups = group_by_table_context(inputs)
            result += format_table_groups(table_groups)
            "#{result}\n"
          end

          def format_form_controls(form_controls)
            result = "🎛️ Form Controls:\n"
            form_controls.each do |name, controls|
              result += format_control_group(name, controls)
            end
            result += "\n"
          end

          def format_labels(labels)
            result = "🏷️ Labels & Headers:\n"
            labels.first(3).each do |label|
              result += "  • #{label.name}: #{label.text.strip}\n"
            end
            result += "  ... and #{labels.size - 3} more\n" if labels.size > 3
            result += "\n"
          end

          def build_header(total_count, text)
            "Found #{total_count} elements containing '#{text}':\n\n"
          end

          def format_each_group(grouped_elements)
            [
              format_inputs_section(grouped_elements[:inputs]),
              format_actions_section(grouped_elements[:actions]),
              format_controls_section(grouped_elements[:form_controls]),
              format_labels_section(grouped_elements[:labels]),
            ].join
          end

          def format_inputs_section(inputs)
            inputs.any? ? format_inputs(inputs) : ""
          end

          def format_actions_section(actions)
            actions.any? ? ActionFormatter.format_actions(actions) : ""
          end

          def format_controls_section(form_controls)
            form_controls.any? ? format_form_controls(form_controls) : ""
          end

          def format_labels_section(labels)
            labels.any? ? format_labels(labels) : ""
          end

          def format_control_group(name, controls)
            result = "\n  #{name.humanize} options:\n"
            controls.each do |control|
              checked = control["checked"] ? " \u2713" : ""
              result += "    • #{control['value']}#{checked}\n"
            end
            result
          end

          def format_table_groups(table_groups)
            return format_single_group(table_groups.values.first) if table_groups.size == 1

            result = ""
            table_groups.each do |(context, group_inputs)|
              result += "\n  #{context}:\n"
              group_inputs.each { |input| result += InputFormatter.format_input_field(input, "    ") }
            end
            result
          end

          def format_single_group(inputs)
            result = ""
            inputs.each { |input| result += InputFormatter.format_input_field(input, "  ") }
            result
          end

          def group_by_table_context(inputs)
            groups = {}
            inputs.each do |input|
              context = find_context(input)
              groups[context] ||= []
              groups[context] << input
            end
            groups
          end

          def find_context(input)
            table = input.ancestors("table").first
            return "Form Fields" unless table

            find_table_context(input)
          end

          def find_table_context(input)
            row = input.ancestors("tr").first
            return "Table" unless row

            find_meaningful_cell_text(row)
          end

          def find_meaningful_cell_text(row)
            meaningful_cell = row.css("td, th").find do |cell|
              cell.text.strip.length > 2 && !cell.text.match?(/^\d+\.?\d*$/)
            end

            meaningful_cell ? meaningful_cell.text.strip[0..30] : "Table"
          end

          def humanize(text)
            text.gsub(/[-_]/, " ").split.map(&:capitalize).join(" ")
          end
        end
      end
    end
  end
end
