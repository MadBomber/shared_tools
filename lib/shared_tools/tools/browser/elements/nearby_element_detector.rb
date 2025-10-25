# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      module Elements
        # Handles detection of interactive elements near text matches
        module NearbyElementDetector
        module_function

          def add_nearby_interactive_elements(elements)
            nearby_elements = []
            elements.each do |element|
              nearby_elements += find_interactive_in_context(element)
            end
            combined = elements.to_a + nearby_elements
            combined.uniq
          end

          def find_interactive_in_context(element)
            interactive_elements = []
            interactive_elements += check_table_context(element)
            interactive_elements += check_parent_containers(element)
            interactive_elements.uniq
          end

          def check_table_context(element)
            elements = []
            table_cell = element.ancestors("td").first || element.ancestors("th").first
            elements += find_interactive_in_container(table_cell) if table_cell
            table_row = element.ancestors("tr").first
            elements += find_interactive_in_container(table_row) if table_row
            if table_cell && table_row
              table = element.ancestors("table").first
              elements += find_interactive_in_same_column(table, table_cell, table_row) if table
            end
            elements
          end

          def find_interactive_in_same_column(table, header_cell, header_row)
            return [] unless table

            column_index = header_row.css("th, td").index(header_cell)
            return [] unless column_index

            interactive_elements = []
            table.css("tbody tr").each do |row|
              interactive_elements += find_column_cell_elements(row, column_index)
            end
            interactive_elements
          end

          def find_column_cell_elements(row, column_index)
            target_cell = row.css("td, th")[column_index]
            return [] unless target_cell

            find_interactive_in_container(target_cell) + find_interactive_in_nested_tables(target_cell, column_index)
          end

          def find_interactive_in_nested_tables(cell, original_column_index)
            interactive_elements = []

            cell.css("table").each do |nested_table|
              nested_table.css("tr").each do |nested_row|
                nested_cells = nested_row.css("td, th")
                if nested_cells[original_column_index]
                  interactive_elements += find_interactive_in_container(nested_cells[original_column_index])
                end
              end
            end

            interactive_elements
          end

          def check_parent_containers(element)
            interactive_elements = []
            parent_container = element.parent
            3.times do
              break unless parent_container
              break if parent_container.is_a?(Nokogiri::XML::Document)

              interactive_elements += find_interactive_in_container(parent_container)
              parent_container = parent_container.parent
            end
            interactive_elements
          end

          def find_interactive_in_container(container)
            return [] unless container

            container.css("input, textarea, select, button, [role='button'], [tabindex='0']")
              .reject { |el| non_interactive_element?(el) }
          end

          def non_interactive_element?(element)
            return true if element["type"] == "hidden"
            return true if element["tabindex"] == "-1"
            return true if element["aria-hidden"] == "true"

            style = element["style"]
            return true if style&.include?("display: none") || style&.include?("visibility: hidden")

            false
          end
        end
      end
    end
  end
end
