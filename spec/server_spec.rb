# frozen_string_literal: true

require "spec_helper"
require "rack/test"

RSpec.describe Nightingale::Server do
  include Rack::Test::Methods

  def app
    Nightingale::Server.tap do |app|
      app.set :environment, :test
      app.disable :protection
    end
  end

  describe "GET /" do
    it "returns the running message" do
      get "/"
      expect(last_response).to be_ok
      expect(last_response.body).to include("Nightingale Server Running")
    end
  end

  describe "GET /ws" do
    it "returns 200 for non-websocket requests with fallback message" do
      get "/ws"
      expect(last_response).to be_ok
      expect(last_response.body).to eq("WebSocket connection required")
    end
  end
end
