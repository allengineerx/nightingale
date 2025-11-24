require 'nightingale'

title "Nightingale Demo"

sidebar do
  markdown "## Controls"
  n = slider "Number", min: 1, max: 10, value: 3, key: :n
  check = slider "Multiplier", min: 1, max: 5, value: 1, key: :mult
end

markdown "# Hello Nightingale"
markdown "This is a demo of the Ruby DSL."

if button "Compute Random Numbers"
  # compute something
  n = session_state[:n] || 3
  mult = session_state[:mult] || 1

  result = (1..n).map { |i| { index: i, value: rand(100) * mult } }

  markdown "### Results"
  dataframe result
end

markdown "---"
markdown "Current session state: #{session_state.inspect}"
