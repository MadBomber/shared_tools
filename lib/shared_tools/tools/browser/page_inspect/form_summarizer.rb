# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      module PageInspect
        # Module to handle form elements summarization for AI agents
        module FormSummarizer
        module_function

          def summarize_data_entry_opportunities(doc)
            fields = find_data_entry_fields(doc)
            return "" if fields.empty?

            format_for_agents(fields)
          end

          def summarize_form_structure(doc)
            fields = doc.css("input, textarea, select")
            return "📝 No form fields available.\n\n" if fields.empty?

            "📝 Form Fields Available: #{fields.size} fields found\n\n"
          end

          def find_data_entry_fields(doc)
            doc.css("input, textarea, select").reject { |f| skip_field?(f) }
          end

          def skip_field?(field)
            field["type"] == "hidden" ||
              field["disabled"] ||
              %w[button submit reset].include?(field["type"])
          end

          def format_for_agents(fields)
            result = "📝 Data Entry Fields:\n"

            # Group important fields first
            date_fields = fields.select { |f| date_field?(f) }
            text_fields = fields.select { |f| text_field?(f) }
            other_fields = fields - date_fields - text_fields

            result += format_field_group("📅 Date Fields", date_fields)
            result += format_field_group("📝 Text Fields", text_fields)
            result += format_field_group("🔧 Other Fields", other_fields)

            "#{result}\n"
          end

          def format_field_group(title, fields)
            return "" if fields.empty?

            result = "#{title}:\n"
            fields.first(8).each { |field| result += format_agent_field(field) }
            result += "  ... and #{fields.size - 8} more\n" if fields.size > 8
            result += "\n"
          end

          def format_agent_field(field)
            label = get_field_label(field)
            id = field["id"] || "no-id"
            value = field["value"] ? " = '#{field['value']}'" : ""
            placeholder = field["placeholder"] ? " [#{field['placeholder']}]" : ""

            "  • #{label} (#{id})#{value}#{placeholder}\n"
          end

          def get_field_label(field)
            return get_associated_label(field) if field["id"]
            return field["placeholder"] if field["placeholder"]

            field_type = field.name == "input" ? (field["type"] || "text") : field.name
            field_type.capitalize
          end

          def get_associated_label(field)
            label = field.document.at_css("label[for='#{field['id']}']")
            return nil unless label&.text

            text = label.text.strip
            text.empty? ? nil : text
          end

          def date_field?(field)
            field["type"] == "date" ||
              field["placeholder"]&.match?(/date|yyyy|mm|dd/i) ||
              get_associated_label(field)&.match?(/date|due/i)
          end

          def text_field?(field)
            %w[text email tel url textarea].include?(field["type"]) ||
              field.name == "textarea"
          end
        end
      end
    end
  end
end
