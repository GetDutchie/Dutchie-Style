# frozen_string_literal: true

require "rubocop"
require "rubocop/rspec/support"
require "dutchie-style"

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense
end
