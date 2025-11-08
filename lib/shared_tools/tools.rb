# frozen_string_literal: true

# Loader file for all tools - loaded automatically by Zeitwerk
# Individual tool collections can be loaded with:
#   require 'shared_tools/tools/disk'    # Load all disk tools
#   require 'shared_tools/tools/browser' # Load all browser tools
#
# Or load individual tools with Zeitwerk autoloading:
#   SharedTools::Tools::Disk::FileReadTool
#   SharedTools::Tools::Browser::VisitTool

module SharedTools
  module Tools
    class Error < StandardError; end
  end
end
