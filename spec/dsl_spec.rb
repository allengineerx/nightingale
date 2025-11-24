# frozen_string_literal: true

require "nightingale"
require "rspec"

RSpec.describe Nightingale::DSL do
  let(:runner) { Nightingale::Runner.new("dummy_path") }

  before do
    Thread.current[:nightingale_runner] = runner
  end

  after do
    Thread.current[:nightingale_runner] = nil
  end

  class TestApp
    include Nightingale::DSL
  end

  let(:app) { TestApp.new }

  describe "#title" do
    it "adds a title component" do
      app.title("Hello")
      expect(runner.components.last).to include(type: "title", props: { text: "Hello" })
    end
  end

  describe "#button" do
    it "adds a button component" do
      app.button("Click me")
      expect(runner.components.last).to include(type: "button", props: hash_including(label: "Click me"))
    end

    it "returns true if clicked" do
      # Mock the event
      runner.instance_variable_set(:@current_event, { "id" => "button_Click me", "event" => "click" })
      expect(app.button("Click me")).to be true
    end
  end

  describe "#slider" do
    it "adds a slider component" do
      app.slider("Value", min: 0, max: 10)
      expect(runner.components.last).to include(type: "slider", props: hash_including(min: 0, max: 10))
    end
  end
end
