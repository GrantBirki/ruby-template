# frozen_string_literal: true

require "coverage"

ROOT = File.expand_path("..", __dir__)
COVERAGE_TARGETS = Dir[File.join(ROOT, "lib/**/*.rb")].map { |path| File.realpath(path) }.freeze

Coverage.start(lines: true, branches: true, methods: true)

require "rspec/core"

def relative_coverage_path(path)
  path.delete_prefix("#{ROOT}/")
end

RSpec.configure do |config|
  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }

  config.after(:suite) do
    result = Coverage.result
    coverage_by_path = result.to_h do |path, data|
      [File.realpath(path), data]
    rescue Errno::ENOENT
      [File.expand_path(path), data]
    end

    uncovered = []
    COVERAGE_TARGETS.each do |path|
      coverage = coverage_by_path[path]
      unless coverage
        uncovered << "#{relative_coverage_path(path)}: not loaded by specs"
        next
      end

      lines = coverage.fetch(:lines)
      File.readlines(path).each_with_index do |_source, index|
        count = lines[index]
        next if count.nil? || count.positive?

        uncovered << "#{relative_coverage_path(path)}:#{index + 1} line"
      end

      coverage.fetch(:branches).each_value do |branches|
        branches.each do |branch, count|
          next if count.positive?

          uncovered << "#{relative_coverage_path(path)}:#{branch[2]} #{branch[0]} branch"
        end
      end

      coverage.fetch(:methods).each do |method, count|
        next if count.positive?

        uncovered << "#{relative_coverage_path(path)}:#{method[2]} method #{method[1]}"
      end
    end

    next if uncovered.empty?

    warn "\nRuby coverage is below 100%:"
    warn uncovered.join("\n")
    exit 1
  end
end
