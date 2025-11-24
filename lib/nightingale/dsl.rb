module Nightingale
  module DSL
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def components
        @components ||= []
      end

      def reset_components!
        @components = []
      end
    end

    def title(text)
      Nightingale::Runner.current.add_component({ type: 'title', props: { text: text } })
    end

    def markdown(text)
      Nightingale::Runner.current.add_component({ type: 'markdown', props: { content: text } })
    end

    def button(label, key: nil)
      key ||= "button_#{label}"
      # Check if this button was clicked in the current event
      clicked = Nightingale::Runner.current.event_triggered?(key, 'click')

      Nightingale::Runner.current.add_component({
        type: 'button',
        id: key,
        props: { label: label, value: clicked }
      })

      clicked
    end

    def slider(label, min:, max:, value: nil, step: 1, key: nil)
      key ||= "slider_#{label}"
      current_value = Nightingale::Runner.current.get_widget_value(key) || value || min

      Nightingale::Runner.current.add_component({
        type: 'slider',
        id: key,
        props: { label: label, min: min, max: max, value: current_value, step: step }
      })

      current_value
    end

    def dataframe(data, key: nil)
      key ||= "dataframe_#{data.object_id}"
      # data should be an array of hashes or similar
      Nightingale::Runner.current.add_component({
        type: 'dataframe',
        id: key,
        props: { data: data }
      })
    end

    def session_state
      Nightingale::Runner.current.session_state
    end

    # Layout helpers could go here (sidebar, etc.)
    def sidebar(&block)
      Nightingale::Runner.current.with_container('sidebar') do
        yield
      end
    end
  end
end
