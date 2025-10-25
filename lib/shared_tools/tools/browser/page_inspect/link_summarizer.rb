# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      module PageInspect
        # Module to handle link elements summarization for AI agents
        module LinkSummarizer
        module_function

          def summarize_key_navigation(doc)
            nav_links = find_navigation_links(doc)
            return "" if nav_links.empty?

            format_navigation(nav_links)
          end

          def find_navigation_links(doc)
            links = doc.css("a[href]").reject { |link| skip_link?(link) }
            links.select { |link| navigation_link?(link) }
          end

          def skip_link?(link)
            href = link["href"]
            return true if href.nil? || href.empty? || href == "#"
            return true if href.start_with?("javascript:")
            return true if link["style"]&.include?("display: none")

            false
          end

          def navigation_link?(link)
            return true if main_navigation?(link)
            return true if workflow_link?(link)

            false
          end

          def main_navigation?(link)
            ancestors = link.ancestors.map { |el| el["class"] }.compact.join(" ")
            nav_indicators = %w[nav navigation menu main-nav primary-nav app-menu breadcrumb]

            nav_indicators.any? { |indicator| ancestors.include?(indicator) }
          end

          def workflow_link?(link)
            text = get_link_text(link).downcase
            workflow_keywords = %w[dashboard home create new add edit settings
                                   invoice estimate customer payment back continue]

            workflow_keywords.any? { |keyword| text.include?(keyword) }
          end

          def get_link_text(link)
            text = link.text.strip
            text = link["title"] if text.empty? && link["title"]
            text = link["aria-label"] if text.empty? && link["aria-label"]

            text.empty? ? "Link" : text
          end

          def format_navigation(links)
            result = "🧭 Key Navigation:\n"

            main_nav = links.select { |l| main_navigation?(l) }
            actions = links.select { |l| workflow_link?(l) && !main_navigation?(l) }

            result += format_link_group(main_nav, "📍 Main Menu")
            result += format_link_group(actions, "🔗 Quick Actions")

            "#{result}\n"
          end

          def format_link_group(links, title)
            return "" if links.empty?

            result = "#{title}:\n"
            links.first(6).each { |link| result += format_nav_link(link) }
            result += "  ... and #{links.size - 6} more\n" if links.size > 6
            result += "\n"
          end

          def format_nav_link(link)
            text = get_link_text(link)
            destination = extract_destination(link["href"])

            "  • #{text}#{destination}\n"
          end

          def extract_destination(href)
            return "" if href.nil? || href.empty?
            return "" unless href.include?("/")

            path = href.split("/").last
            return "" if path.nil? || path.empty?

            " → #{path}"
          end
        end
      end
    end
  end
end
