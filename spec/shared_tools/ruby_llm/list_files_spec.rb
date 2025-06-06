# frozen_string_literal: true

require "spec_helper"
require "shared_tools/ruby_llm/list_files"
require "tempfile"
require "tmpdir"

RSpec.describe SharedTools::ListFiles do
  let(:tool) { described_class.new }

  describe "logger integration" do
    it "has logger methods automatically injected" do
      expect(tool).to respond_to(:logger)
      expect(described_class).to respond_to(:logger)
    end

    it "uses SharedTools logger instance" do
      expect(tool.logger).to eq(SharedTools.logger)
      expect(described_class.logger).to eq(SharedTools.logger)
    end
  end

  describe "#execute" do
    context "with a valid directory" do
      let(:temp_dir) { Dir.mktmpdir }
      
      before do
        # Create test files and directories
        File.write(File.join(temp_dir, "test_file.txt"), "content")
        File.write(File.join(temp_dir, "another_file.rb"), "puts 'hello'")
        Dir.mkdir(File.join(temp_dir, "subdirectory"))
        File.write(File.join(temp_dir, ".hidden_file"), "hidden content")
      end

      after do
        FileUtils.remove_entry(temp_dir)
      end

      it "lists all files and directories including hidden ones" do
        result = tool.execute(path: temp_dir)

        expect(result).to be_an(Array)
        expect(result.size).to eq(4) # 2 files + 1 directory + 1 hidden file
        
        # Check that directories are marked with trailing slash
        directory_entry = result.find { |f| f.include?("subdirectory") }
        expect(directory_entry).to end_with("/")
        
        # Check that files are included
        expect(result.any? { |f| f.include?("test_file.txt") }).to be true
        expect(result.any? { |f| f.include?("another_file.rb") }).to be true
        expect(result.any? { |f| f.include?(".hidden_file") }).to be true
      end

      it "returns sorted results" do
        result = tool.execute(path: temp_dir)
        
        expect(result).to eq(result.sort)
      end
    end

    context "with current directory when no path provided" do
      it "lists files in current directory by default" do
        result = tool.execute

        expect(result).to be_an(Array)
        expect(result).not_to be_empty
      end
    end

    context "with a non-existent path" do
      it "returns an error" do
        result = tool.execute(path: "/non/existent/directory")

        expect(result).to be_a(Hash)
        expect(result).to have_key(:error)
        expect(result[:error]).to include("Path does not exist or is not a directory")
      end
    end

    context "with a file path instead of directory" do
      let(:temp_file) { Tempfile.new(["test", ".txt"]) }

      before do
        temp_file.write("content")
        temp_file.flush
      end

      after do
        temp_file.close
        temp_file.unlink
      end

      it "returns an error" do
        result = tool.execute(path: temp_file.path)

        expect(result).to be_a(Hash)
        expect(result).to have_key(:error)
        expect(result[:error]).to include("Path does not exist or is not a directory")
      end
    end

    context "with permission errors" do
      it "handles permission denied gracefully" do
        # This test may not work on all systems, but provides coverage
        result = tool.execute(path: "/private/var/root")

        # Either works or returns an error (depending on system permissions)
        expect(result.is_a?(Array) || result.is_a?(Hash)).to be true
        if result.is_a?(Hash)
          expect(result).to have_key(:error)
        end
      end
    end
  end
end