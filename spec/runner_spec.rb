# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe Nightingale::Runner do
  let(:script_content) { 'title "Hello World"' }
  let(:script_file) do
    file = Tempfile.new(["test_script", ".rb"])
    file.write(script_content)
    file.rewind
    file
  end
  let(:runner) { described_class.new(script_file.path) }

  after do
    script_file.close
    script_file.unlink
  end

  describe "#run" do
    it "executes the script and returns components" do
      components = runner.run
      expect(components).to be_an(Array)
      expect(components.first).to include(type: "title", props: { text: "Hello World" })
    end

    context "with errors" do
      let(:script_content) { 'raise "Boom"' }

      it "captures errors and adds an error component" do
        components = runner.run
        expect(components.first).to include(type: "error")
        expect(components.first[:props][:message]).to eq("Boom")
      end
    end
  end
end
