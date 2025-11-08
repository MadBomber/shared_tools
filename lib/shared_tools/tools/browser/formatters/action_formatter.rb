# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      module Formatters
        # Handles formatting of action elements (buttons, links)
        module ActionFormatter
        module_function

          def format_actions(actions)
            result = "⚡ Available Actions:\n"
            actions.first(5).each do |action|
              result += format_action_element(action)
            end
            result += "  ... and #{actions.size - 5} more\n" if actions.size > 5
            result += "\n"
          end

          def format_action_element(action)
            text = action.text.strip
            selector = get_action_selector(action)
            "  • #{text} (#{selector})\n"
          end

          def get_action_selector(action)
            return action["id"] if action["id"] && !action["id"].empty?
            return "text:#{action.text.strip}" if action.text.strip.length > 2
            return action["class"].split.first if action["class"]

            "css-needed"
          end
        end
      end
    end
  end
end
