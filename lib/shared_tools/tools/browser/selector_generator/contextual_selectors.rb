# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      module SelectorGenerator
        # Context-aware selector generation for complex elements
        module ContextualSelectors
          def generate_contextual_selectors(element)
            selectors = []
            selectors.concat(parent_class_selectors(element))
            selectors.concat(label_based_selectors(element))
            selectors.concat(position_based_selectors(element))
            selectors
          end

          # Generate selectors based on parent container classes
          def parent_class_selectors(element)
            significant_parent = find_significant_parent(element)
            return [] unless significant_parent

            parent_class = most_specific_class(significant_parent)
            return [] unless parent_class

            build_parent_selector(element, parent_class)
          end

          # Build selector with parent class context
          def build_parent_selector(element, parent_class)
            base = ".#{parent_class} #{element.name}"
            return ["#{base}[placeholder=\"#{element['placeholder']}\"]"] if element["placeholder"]
            return ["#{base}[type=\"#{element['type']}\"]"] if element["type"]

            [base]
          end

          # Find parent with meaningful class (not generic like 'row' or 'col')
          def find_significant_parent(element)
            parent = element.parent
            while parent && parent.name != "body"
              return parent if element_has_significant_class?(parent)

              parent = parent.parent
            end
            nil
          end

          # Check if element has significant class
          def element_has_significant_class?(element)
            classes = element["class"]&.split || []
            classes.any? { |c| significant_class?(c) }
          end

          # Check if class name is likely to be meaningful/specific
          def significant_class?(class_name)
            return false if class_name.length < 4
            return false if generic_class?(class_name)

            class_name.match?(/[a-z]+[-_]?[a-z]+/i)
          end

          # Common generic class names to ignore
          def generic_class?(class_name)
            %w[row col container wrapper inner outer main].include?(class_name.downcase)
          end

          # Get most specific (longest) class name
          def most_specific_class(element)
            classes = element["class"]&.split || []
            classes.select { |c| significant_class?(c) }.max_by(&:length)
          end

          # Generate selectors based on label associations
          def label_based_selectors(element)
            return [] unless stable_id?(element)

            label = find_label_for_element(element)
            label ? ["#{element.name}##{element['id']}"] : []
          end

          # Check if element has stable (non-React) ID
          def stable_id?(element)
            id = element["id"]
            id && !id.empty? && !id.match?(/^:r[0-9a-z]+:$/i)
          end

          # Find label element associated with this element
          def find_label_for_element(element)
            element.document.at_css("label[for=\"#{element['id']}\"]")
          end

          # Generate position-based selectors for similar elements
          def position_based_selectors(element)
            siblings = find_similar_siblings(element)
            return [] unless siblings.size > 1

            index = siblings.index(element) + 1
            parent_context = parent_context_prefix(element)
            build_position_selector(element, index, parent_context)
          end

          # Build nth-of-type selector
          def build_position_selector(element, index, parent_context = "")
            nth = ":nth-of-type(#{index})"
            base = "#{parent_context}#{element.name}#{nth}"
            return ["#{parent_context}#{element.name}[type=\"#{element['type']}\"]#{nth}"] if element["type"]
            if element["placeholder"]
              return ["#{parent_context}#{element.name}[placeholder=\"#{element['placeholder']}\"]#{nth}"]
            end

            [base]
          end

          # Find sibling elements of same type with similar attributes
          def find_similar_siblings(element)
            return [] unless element.parent

            element.parent.css(element.name).select { |sibling| same_key_attributes?(element, sibling) }
          end

          # Check if two elements have same key attributes
          def same_key_attributes?(elem1, elem2)
            return false unless elem1.name == elem2.name

            elem1.name == "input" ? elem1["type"] == elem2["type"] : true
          end

          # Get parent context for more specific position selectors
          def parent_context_prefix(element)
            parent = find_significant_parent(element)
            return "" unless parent

            parent_class = most_specific_class(parent)
            parent_class ? ".#{parent_class} " : ""
          end
        end
      end
    end
  end
end
