# frozen_string_literal: true

require_relative "example"

first = ARGV[0].to_i
second = ARGV[1].to_i

rbt = RubyTemplate.new

puts rbt.simple_addition(first, second)
