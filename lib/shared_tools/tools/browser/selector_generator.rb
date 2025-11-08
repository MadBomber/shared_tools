# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      # Generates stable CSS selectors for HTML elements
      module SelectorGenerator
        extend BaseSelectors
        extend ContextualSelectors

      module_function

        def generate_stable_selectors(element)
          return [] unless valid_element?(element)

          selectors = []
          selectors.concat(generate_by_type(element))
          selectors.concat(generate_contextual_selectors(element))
          selectors.compact.uniq
        end

        def generate_by_type(element)
          case element.name
          when "input" then generate_input_selectors(element)
          when "textarea" then generate_textarea_selectors(element)
          when "select" then generate_select_selectors(element)
          else []
          end
        end

        def valid_element?(element)
          element.respond_to?(:name) && element.respond_to?(:parent)
        end

        def generate_input_selectors(element)
          selectors = []
          selectors.concat(placeholder_selector(element, "input"))
          selectors.concat(aria_label_selector(element, "input"))
          selectors.concat(type_selectors(element))
          selectors.concat(attribute_selectors(element, "input"))
          selectors
        end

        def generate_textarea_selectors(element)
          placeholder_selector(element, "textarea") + name_selector(element, "textarea")
        end

        def generate_select_selectors(element)
          name_selector(element, "select") + aria_label_selector(element, "select")
        end

        def type_selectors(element)
          return [] unless valid_attribute?(element["type"])

          base = "input[type=\"#{element['type']}\"]"
          [base, amount_class_selector(base, element)].compact
        end

        def amount_class_selector(base, element)
          element["class"]&.include?("wv-input--amount") ? "#{base}.wv-input--amount" : nil
        end

        def attribute_selectors(element, tag)
          maxlength_selector(element, tag) + name_selector(element, tag)
        end

        def valid_attribute?(attribute)
          attribute && attribute.strip.length.positive?
        end
      end
    end
  end
end
