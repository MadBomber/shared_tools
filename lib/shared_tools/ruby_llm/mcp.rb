# shared_tools/ruby_llm/mcp.rb
# This file loads all Ruby files in the mcp directory

# Get the directory path
mcp_dir = File.join(__dir__, 'mcp')

# Load all .rb files in the mcp directory
Dir.glob(File.join(mcp_dir, '*.rb')).each do |file|
  require file
end
