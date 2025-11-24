# frozen_string_literal: true

require "spec_helper"
require "nightingale/cli"

RSpec.describe Nightingale::CLI do
  describe ".new_project" do
    let(:project_name) { "test_project" }
    let(:gem_root) { File.expand_path("..", __dir__) }

    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:cp_r)
      allow(FileUtils).to receive(:rm_rf)
      allow(File).to receive(:directory?).and_return(true)
      allow(File).to receive(:write)
      allow(Dir).to receive(:chdir).and_yield
      allow(described_class).to receive(:system)
      allow(described_class).to receive(:puts) # Silence output
    end

    it "creates the project directory" do
      described_class.new_project(project_name)
      expect(FileUtils).to have_received(:mkdir_p).with(project_name)
    end

    it "copies the frontend template" do
      described_class.new_project(project_name)
      expect(FileUtils).to have_received(:cp_r).with(
        File.join(gem_root, "frontend"),
        File.join(project_name, "frontend")
      )
    end

    it "creates app.rb and Gemfile" do
      described_class.new_project(project_name)
      expect(File).to have_received(:write).with(File.join(project_name, "app.rb"), anything)
      expect(File).to have_received(:write).with(File.join(project_name, "Gemfile"), anything)
    end

    it "installs dependencies" do
      described_class.new_project(project_name)
      expect(described_class).to have_received(:system).with("npm install")
      expect(described_class).to have_received(:system).with(/npx shadcn@latest add/)
    end
  end
end
