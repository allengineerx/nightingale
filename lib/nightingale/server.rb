# frozen_string_literal: true

require "sinatra/base"
require "faye/websocket"
require "json"
require "listen"

module Nightingale
  class Server < Sinatra::Base
    set :server, "puma"
    set :bind, "0.0.0.0"
    set :port, 4567

    # Store runners per session (connection)
    # In a real app, we'd use a proper session store
    @@runners = {}
    @@connections = []

    def self.run!
      # Start file watcher
      script_path = ENV["NIGHTINGALE_SCRIPT"]
      if script_path && File.exist?(script_path)
        puts "Watching #{script_path} for changes..."
        listener = Listen.to(File.dirname(script_path),
                             only: /#{File.basename(script_path)}$/) do |modified, added, removed|
          puts "File changed: #{modified}"
          # Trigger rerun for all connections
          @@connections.each do |ws|
            runner = @@runners[ws.object_id]
            next unless runner

            puts "Rerunning for connection #{ws.object_id}"
            tree = runner.run
            ws.send({ type: "render", components: tree }.to_json)
          end
        end
        listener.start
      end

      super
    end

    get "/" do
      "Nightingale Server Running. Connect via WebSocket at /ws"
    end

    get "/ws" do
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env)

        ws.on :open do |event|
          puts "WebSocket connection open"
          @@connections << ws

          # Initialize runner for this connection
          script_path = ENV["NIGHTINGALE_SCRIPT"]
          runner = Nightingale::Runner.new(script_path)
          @@runners[ws.object_id] = runner

          # Initial run
          tree = runner.run
          ws.send({ type: "render", components: tree }.to_json)
        end

        ws.on :message do |event|
          data = JSON.parse(event.data)
          puts "Received message: #{data}"

          if data["type"] == "event"
            runner = @@runners[ws.object_id]
            if runner
              # Rerun with event
              # We pass the widget value from the event if applicable
              # But usually the frontend sends all widget values or we track them?
              # For MVP, let's assume the event contains the value of the widget that changed.
              # And maybe we need to sync other widget values?
              # Streamlit sends all widget states.
              # For MVP, let's assume we just update the specific widget value in the runner's state?
              # Or we pass it to run.

              widget_values = data["values"] || {}
              widget_values[data["id"]] = data["value"] if data["id"] && data.key?("value")

              tree = runner.run(data, widget_values)
              ws.send({ type: "render", components: tree }.to_json)
            end
          end
        end

        ws.on :close do |event|
          puts "WebSocket connection closed"
          @@connections.delete(ws)
          @@runners.delete(ws.object_id)
          ws = nil
        end

        return ws.rack_response
      else
        # Fallback for non-WS requests
        "WebSocket connection required"
      end
    end
  end
end
