# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      module PageInspect
        # Module to handle button elements summarization for AI agents
        module ButtonSummarizer
        module_function

          def summarize_primary_actions(doc)
            buttons = find_primary_buttons(doc)
            return "" if buttons.empty?

            format_primary_actions(buttons)
          end

          def find_primary_buttons(doc)
            all_buttons = doc.css('button, input[type="button"], input[type="submit"], [role="button"], [tabindex="0"]')
            all_buttons.select { |btn| primary_action?(btn) && !skip_button?(btn) }
          end

          def skip_button?(button)
            button["disabled"] ||
              button["style"]&.include?("display: none") ||
              button["aria-hidden"] == "true"
          end

          def primary_action?(button)
            return true if button["type"] == "submit"
            return true if primary_button_text?(button)
            return true if primary_button_class?(button)
            return true if workflow_action_button?(button)

            false
          end

          def primary_button_text?(button)
            text = get_button_text(button).downcase

            # Direct keyword matches
            primary_keywords = %w[save submit continue next finish send create update
                                  delete cancel close done confirm proceed add edit]
            return true if primary_keywords.any? { |keyword| text.include?(keyword) }

            # Workflow action patterns
            return true if text.include?("add") && text.match?(/item|customer|discount|product|contact|line/)
            return true if text.include?("choose") || text.include?("select")

            false
          end

          def primary_button_class?(button)
            classes = button["class"] || ""

            # Generic primary button patterns (universal)
            primary_classes = %w[primary submit btn-primary button--primary save continue]
            generic_match = primary_classes.any? { |css_class| classes.include?(css_class) }

            # Generic link-button patterns (works across frameworks)
            link_button_patterns = %w[button--link btn-link link-button button-link]
            link_match = link_button_patterns.any? { |pattern| classes.include?(pattern) }

            generic_match || link_match
          end

          def workflow_action_button?(button)
            text = get_button_text(button).downcase

            # Check for common workflow patterns
            return true if text.match?(/add.*(item|customer|discount|product|contact)/i)
            return true if text.match?(/edit.*(column|field|profile)/i)
            return true if text.match?(/choose.*(different|customer)/i)
            return true if text.match?(/(create|new).*(item|customer|product)/i)

            false
          end

          def get_button_text(button)
            text = button.text.strip
            text = button["value"] if text.empty? && button["value"]
            text = button["aria-label"] if text.empty? && button["aria-label"]

            text.empty? ? "Button" : text
          end

          def format_primary_actions(buttons)
            result = "⚡ Primary Actions:\n"

            # Group by importance
            critical = buttons.select(&method(:critical_action?))
            regular = buttons - critical

            result += format_button_group(critical, "🔥 Critical")
            result += format_button_group(regular, "📝 Actions")

            "#{result}\n"
          end

          def critical_action?(button)
            text = get_button_text(button).downcase
            %w[save submit send create].any? do |keyword|
              text.include?(keyword)
            end
          end

          def format_button_group(buttons, title)
            return "" if buttons.empty?

            result = "#{title}:\n"
            buttons.first(5).each do |btn|
              result += format_action_button(btn)
            end
            result += "  ... and #{buttons.size - 5} more\n" if buttons.size > 5
            result += "\n"
          end

          def format_action_button(button)
            text = get_button_text(button)
            selector = get_button_selector(button)

            "  • #{text} (#{selector})\n"
          end

          def get_button_selector(button)
            return button["id"] if button["id"] && !button["id"].empty?
            return "text:#{get_button_text(button)}" if distinctive_text?(button)

            "css-selector-needed"
          end

          def distinctive_text?(button)
            text = get_button_text(button)
            text.length > 2 && text != "Button"
          end
        end
      end
    end
  end
end
