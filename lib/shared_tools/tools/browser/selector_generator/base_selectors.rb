# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      module SelectorGenerator
        # Basic selector generation methods
        module BaseSelectors
          def placeholder_selector(element, tag)
            valid_attribute?(element["placeholder"]) ? ["#{tag}[placeholder=\"#{element['placeholder']}\"]"] : []
          end

          def aria_label_selector(element, tag)
            valid_attribute?(element["aria-label"]) ? ["#{tag}[aria-label=\"#{element['aria-label']}\"]"] : []
          end

          def name_selector(element, tag)
            valid_attribute?(element["name"]) ? ["#{tag}[name=\"#{element['name']}\"]"] : []
          end

          def maxlength_selector(element, tag)
            valid_attribute?(element["maxlength"]) ? ["#{tag}[maxlength=\"#{element['maxlength']}\"]"] : []
          end
        end
      end
    end
  end
end
