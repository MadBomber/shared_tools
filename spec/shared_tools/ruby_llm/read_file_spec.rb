# frozen_string_literal: true

require "spec_helper"
require "shared_tools/ruby_llm/read_file"
require "tempfile"

RSpec.describe SharedTools::ReadFile do
  let(:tool) { described_class.new }

  describe "logger integration" do
    it "has logger methods available" do
      expect(RubyLLM).to respond_to(:logger)
    end

    it "logger is functional" do
      expect(RubyLLM.logger).to respond_to(:info)
      expect(RubyLLM.logger).to respond_to(:debug)
      expect(RubyLLM.logger).to respond_to(:error)
    end
  end

  describe "#execute" do
    context "with an existing file" do
      let(:temp_file) { Tempfile.new(["test", ".txt"]) }
      let(:content) { "This is test content" }

      before do
        temp_file.write(content)
        temp_file.flush
      end

      after do
        temp_file.close
        temp_file.unlink
      end

      it "reads the file content" do
        result = tool.execute(path: temp_file.path)
        expect(result).to eq(content)
      end
    end

    context "with a non-existent file" do
      it "returns an error" do
        result = tool.execute(path: "/non/existent/file.txt")
        expect(result).to be_a(Hash)
        expect(result).to have_key(:error)
        expect(result[:error]).to include("File does not exist")
      end
    end

    context "with a directory path" do
      it "returns an error" do
        result = tool.execute(path: Dir.pwd)
        expect(result).to be_a(Hash)
        expect(result).to have_key(:error)
        expect(result[:error]).to include("Path is a directory")
      end
    end

    context "with unexpected exceptions" do
      it "handles exceptions during file read operations gracefully" do
        temp_file = Tempfile.new(["test", ".txt"])
        temp_file.write("test content")
        temp_file.flush

        # Mock File.read to raise an exception
        allow(File).to receive(:read).and_raise(StandardError.new("File corrupted"))

        result = tool.execute(path: temp_file.path)

        expect(result).to be_a(Hash)
        expect(result).to have_key(:error)
        expect(result[:error]).to eq("File corrupted")

        temp_file.close
        temp_file.unlink
      end
    end
  end
end