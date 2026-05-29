# frozen_string_literal: true

require "coverage"

ROOT = File.expand_path("..", __dir__)
COVERAGE_TARGETS = Dir[File.join(ROOT, "lib/**/*.rb")].map { |path| File.realpath(path) }.freeze

Coverage.start(lines: true)

require "rspec"

def coverage_lines(data)
  data.is_a?(Hash) ? data.fetch(:lines) : data
end

def relative_coverage_path(path)
  path.delete_prefix("#{ROOT}/")
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }

  config.after(:suite) do
    result = Coverage.result
    coverage_by_path = result.to_h do |path, data|
      [File.realpath(path), coverage_lines(data)]
    rescue Errno::ENOENT
      [File.expand_path(path), coverage_lines(data)]
    end

    uncovered = []
    COVERAGE_TARGETS.each do |path|
      lines = coverage_by_path[path]
      unless lines
        uncovered << "#{relative_coverage_path(path)}: not loaded by specs"
        next
      end

      File.readlines(path).each_with_index do |_source, index|
        count = lines[index]
        next if count.nil? || count.positive?

        uncovered << "#{relative_coverage_path(path)}:#{index + 1}"
      end
    end

    next if uncovered.empty?

    warn "\nRuby line coverage is below 100%:"
    warn uncovered.join("\n")
    exit 1
  end
end
