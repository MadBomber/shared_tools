# frozen_string_literal: true

require "spec_helper"
require "shared_tools/ruby_llm/edit_file"
require "tempfile"

RSpec.describe SharedTools::EditFile do
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
    context "with an existing file" do
      let(:temp_file) { Tempfile.new(["test", ".txt"]) }
      let(:original_content) { "Hello world\nThis is a test\nHello again" }

      before do
        temp_file.write(original_content)
        temp_file.flush
      end

      after do
        temp_file.close
        temp_file.unlink
      end

      it "replaces first occurrence by default" do
        result = tool.execute(
          path: temp_file.path,
          old_str: "Hello",
          new_str: "Hi"
        )

        expect(result).to include(success: true, matches: 2, replaced: 1)
        updated_content = File.read(temp_file.path)
        expect(updated_content).to eq("Hi world\nThis is a test\nHello again")
      end

      it "replaces all occurrences when replace_all is true" do
        result = tool.execute(
          path: temp_file.path,
          old_str: "Hello",
          new_str: "Hi",
          replace_all: true
        )

        expect(result).to include(success: true, matches: 2, replaced: 2)
        updated_content = File.read(temp_file.path)
        expect(updated_content).to eq("Hi world\nThis is a test\nHi again")
      end

      it "returns warning when no matches found" do
        result = tool.execute(
          path: temp_file.path,
          old_str: "nonexistent",
          new_str: "replacement"
        )

        expect(result).to include(success: false)
        expect(result).to have_key(:warning)
        expect(result[:warning]).to include("No matches found")
      end
    end

    context "with a non-existent file" do
      let(:new_file_path) { "/tmp/test_new_file_#{Time.now.to_i}.txt" }

      after do
        File.delete(new_file_path) if File.exist?(new_file_path)
      end

      it "creates a new file when it doesn't exist" do
        result = tool.execute(
          path: new_file_path,
          old_str: "",
          new_str: "New content"
        )

        expect(result).to include(success: true)
        expect(File.exist?(new_file_path)).to be true
        expect(File.read(new_file_path)).to eq("New content")
      end

      it "returns warning when trying to replace in empty new file" do
        result = tool.execute(
          path: new_file_path,
          old_str: "nonexistent",
          new_str: "replacement"
        )

        expect(result).to include(success: false)
        expect(result).to have_key(:warning)
      end
    end

    context "with file permission errors" do
      it "returns error when file cannot be written" do
        # Skip this test if running as root or if the path is accessible
        skip "Cannot test permission errors in this environment" if File.writable?("/root") || !Dir.exist?("/root")
        
        # Use a path that would cause permission error
        result = tool.execute(
          path: "/root/protected_file.txt",
          old_str: "test",
          new_str: "replacement"
        )

        expect(result).to have_key(:error)
      end
    end
  end
end