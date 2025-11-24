# frozen_string_literal: true

require_relative "nightingale/version"
require_relative "nightingale/cli"
require_relative "nightingale/server"
require_relative "nightingale/runner"
require_relative "nightingale/dsl"

module Nightingale
  class Error < StandardError; end
end
