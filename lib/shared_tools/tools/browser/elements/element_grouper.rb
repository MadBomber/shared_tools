# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      module Elements
        # Groups HTML elements by their relevance for data entry
        module ElementGrouper
        module_function

          def group_for_data_entry(elements, text)
            groups = {
              inputs: [], # text, number, email inputs - primary targets
              form_controls: {}, # radio buttons, checkboxes grouped by name
              labels: [], # labels, headers, spans
              actions: [], # buttons and actionable elements
            }

            elements.each do |element|
              categorize_element(element, groups, text)
            end

            groups
          end

          def categorize_element(element, groups, text)
            case element.name.downcase
            when "input"
              categorize_input_element(element, groups)
            when "textarea", "select"
              groups[:inputs] << element
            when "button"
              groups[:actions] << element if contains_text_match?(element, text)
            when "label", "span", "div", "th"
              groups[:labels] << element if contains_text_match?(element, text)
            end
          end

          def categorize_input_element(element, groups)
            if data_entry_input?(element)
              groups[:inputs] << element
            else
              group_form_control(element, groups[:form_controls])
            end
          end

          def data_entry_input?(element)
            # Handle missing type attribute - HTML default is "text"
            type = (element["type"] || "text").downcase

            # Include common data entry input types
            %w[text number email tel url date datetime-local time month week
               password search].include?(type)
          end

          def group_form_control(element, form_controls)
            type = (element["type"] || "text").downcase
            return unless %w[radio checkbox].include?(type)

            name = element["name"] || "unnamed"
            form_controls[name] ||= []
            form_controls[name] << element
          end

          def contains_text_match?(element, text)
            element.text.downcase.include?(text.downcase) ||
              element["value"]&.downcase&.include?(text.downcase)
          end
        end
      end
    end
  end
end
