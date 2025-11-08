# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      # Utility methods for browser inspection tools that handle HTML document cleaning
      # and various element searching functionalities.
      module InspectUtils
        def cleaned_document(html:)
          clean_document(Nokogiri::HTML(html))
        end

        def clean_document(doc)
          doc.css("link, style, script").each(&:remove)
          doc
        end

        def ci_contains(attribute, value)
          "contains(translate(#{attribute}, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', " \
            "'abcdefghijklmnopqrstuvwxyz'), '#{value}')"
        end

        def find_elements_with_matching_text(doc, text_downcase)
          xpath_conditions = [
            ci_contains("text()", text_downcase),
            ci_contains("@value", text_downcase),
            ci_contains("@placeholder", text_downcase),
            ci_contains("@type", text_downcase),
          ].join(" or ")

          doc.xpath("//*[#{xpath_conditions}]")
        end

        def add_elements_from_matching_labels(doc, text_downcase, elements)
          label_condition = ci_contains(".//text()", text_downcase)
          matching_labels = doc.xpath("//label[#{label_condition}]")

          matching_labels.each do |label|
            for_attr = label["for"]
            next unless for_attr && !for_attr.empty?

            associated_input = doc.css("[id='#{for_attr}']")
            elements += associated_input if associated_input.any?
          end

          elements
        end
      end
    end
  end
end
