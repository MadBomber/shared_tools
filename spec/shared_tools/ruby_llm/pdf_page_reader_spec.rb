# frozen_string_literal: true

require "spec_helper"
require "shared_tools/ruby_llm/pdf_page_reader"

RSpec.describe SharedTools::PdfPageReader do
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
    context "with a non-existent PDF file" do
      it "returns an error" do
        result = tool.execute(
          page_numbers: "1,2,3",
          doc_path: "/non/existent/file.pdf"
        )

        expect(result).to be_a(Hash)
        expect(result).to have_key(:error)
      end
    end

    context "with invalid file format" do
      let(:temp_file) { Tempfile.new(["test", ".txt"]) }

      before do
        temp_file.write("This is not a PDF file")
        temp_file.flush
      end

      after do
        temp_file.close
        temp_file.unlink
      end

      it "returns an error for non-PDF files" do
        result = tool.execute(
          page_numbers: "1",
          doc_path: temp_file.path
        )

        expect(result).to be_a(Hash)
        expect(result).to have_key(:error)
      end
    end

    # Note: Testing with actual PDF files would require creating test fixtures
    # This provides coverage for the error handling paths and basic functionality
    context "with page number parsing" do
      before do
        # Mock PDF::Reader to avoid needing actual PDF files
        mock_pdf = double("PDF::Reader")
        mock_pages = [
          double("Page", text: "Content of page 1"),
          double("Page", text: "Content of page 2"),
          double("Page", text: "Content of page 3")
        ]
        allow(mock_pdf).to receive(:pages).and_return(mock_pages)
        allow(PDF::Reader).to receive(:new).and_return(mock_pdf)
      end

      it "parses comma-separated page numbers correctly" do
        result = tool.execute(
          page_numbers: "1, 2, 3",
          doc_path: "dummy.pdf"
        )

        expect(result).to be_a(Hash)
        expect(result[:requested_pages]).to eq([1, 2, 3])
        expect(result[:total_pages]).to eq(3)
        expect(result[:pages]).to be_an(Array)
        expect(result[:pages].size).to eq(3)
      end

      it "handles single page numbers" do
        result = tool.execute(
          page_numbers: "2",
          doc_path: "dummy.pdf"
        )

        expect(result[:requested_pages]).to eq([2])
        expect(result[:pages].size).to eq(1)
        expect(result[:pages][0][:page]).to eq(2)
        expect(result[:pages][0][:text]).to eq("Content of page 2")
      end

      it "identifies invalid page numbers" do
        result = tool.execute(
          page_numbers: "1, 5, 10",
          doc_path: "dummy.pdf"
        )

        expect(result[:invalid_pages]).to eq([5, 10])
        expect(result[:pages].size).to eq(1) # Only page 1 is valid
      end

      it "handles page numbers outside valid range" do
        result = tool.execute(
          page_numbers: "0, -1, 4",
          doc_path: "dummy.pdf"
        )

        expect(result[:invalid_pages]).to eq([0, -1, 4])
        expect(result[:pages]).to be_empty
      end

      it "returns structured page data" do
        result = tool.execute(
          page_numbers: "1, 2",
          doc_path: "dummy.pdf"
        )

        expect(result[:pages]).to all(have_key(:page))
        expect(result[:pages]).to all(have_key(:text))
        expect(result[:pages][0][:page]).to eq(1)
        expect(result[:pages][1][:page]).to eq(2)
      end
    end
  end
end