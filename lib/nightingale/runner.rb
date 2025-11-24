# frozen_string_literal: true

require "json"

module Nightingale
  class Runner
    attr_reader :components, :session_state

    def self.current
      Thread.current[:nightingale_runner]
    end

    def initialize(script_path)
      @script_path = script_path
      @components = []
      @session_state = {}
      @widget_values = {}
      @current_event = nil
      @container_stack = []
    end

    def run(event = nil, widget_values = {})
      @components = []
      @current_event = event
      @widget_values.merge!(widget_values) if widget_values

      Thread.current[:nightingale_runner] = self

      begin
        # We load the script content and eval it
        # This is a simple way to execute it.
        # In a real app, we might want to use a separate process or more isolation.
        content = File.read(@script_path)

        # Create a context to evaluate in
        context = Object.new
        context.extend(Nightingale::DSL)

        context.instance_eval(content, @script_path)
      rescue StandardError => e
        puts "Error running script: #{e.message}"
        puts e.backtrace
        add_component({ type: "error", props: { message: e.message, backtrace: e.backtrace } })
      ensure
        Thread.current[:nightingale_runner] = nil
      end

      @components
    end

    def add_component(component)
      if @container_stack.any?
        parent = @container_stack.last
        parent[:children] ||= []
        parent[:children] << component
      else
        @components << component
      end
    end

    def with_container(type)
      container = { type: type, props: {}, children: [] }
      add_component(container)
      @container_stack.push(container)
      yield
      @container_stack.pop
    end

    def get_widget_value(key)
      @widget_values[key]
    end

    def event_triggered?(key, event_type)
      return false unless @current_event

      @current_event["id"] == key && @current_event["event"] == event_type
    end
  end
end
