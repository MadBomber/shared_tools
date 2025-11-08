# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      module PageInspect
        # Module to handle HTML formatting and summary generation for AI agents
        module HtmlSummarizer
        module_function

          def summarize_interactive_elements(doc)
            title = doc.at_css("title")&.text || "Untitled Page"

            summary = "#{title}\n\n"

            # Primary focus: What can agents fill out?
            data_entry = FormSummarizer.summarize_data_entry_opportunities(doc)
            summary += data_entry unless data_entry.empty?

            # Secondary: What actions can agents take?
            primary_actions = ButtonSummarizer.summarize_primary_actions(doc)
            summary += primary_actions unless primary_actions.empty?

            # Tertiary: Key navigation (only if relevant)
            navigation = LinkSummarizer.summarize_key_navigation(doc)
            summary += navigation unless navigation.empty?

            # Fallback: If no data entry found, show form structure
            summary += FormSummarizer.summarize_form_structure(doc) if data_entry.empty?

            summary.strip
          end
        end
      end
    end
  end
end
