# frozen_string_literal: true

require "Dutchie/Style/version"

module Dutchie
  module Style
    class Error < StandardError; end

    # Returns the absolute path to the default configuration file
    def self.config_path
      File.expand_path("../../config/default.yml", __dir__)
    end

    # Returns the gem's root directory
    def self.root
      File.expand_path("../..", __dir__)
    end
  end
end
