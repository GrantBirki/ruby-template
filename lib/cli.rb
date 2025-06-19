# frozen_string_literal: true

require "octokit"
require_relative "example"

_ = Octokit::Client.new(access_token: nil)

first_value = 1
second_value = 2

rbt = RubyTemplate.new

puts rbt.simple_addition(first_value, second_value)
