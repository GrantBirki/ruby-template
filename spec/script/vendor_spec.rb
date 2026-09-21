# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

describe "script/vendor" do
  let(:original_lockfile) { "GEM\n  remote: https://rubygems.org/\n  specs:\n    example (1.0.0)\n\n" }
  let(:updated_lockfile) { original_lockfile.sub("1.0.0", "1.1.0") }
  let(:lockfile_path) { File.join(@directory, "Gemfile.lock") }
  let(:commands) { [] }
  let(:created_at) { "2000-01-01T00:00:00Z" }
  let(:metadata_error) { nil }
  let(:cache_error) { nil }

  around do |example|
    Dir.mktmpdir("ruby-template-vendor") do |directory|
      @directory = directory
      File.write(lockfile_path, original_lockfile)
      example.run
    end
  end

  let(:vendor_module) do
    path = File.expand_path("../../script/vendor", __dir__)
    namespace = Module.new
    namespace.module_eval(File.read(path), path)
    namespace.send(:remove_const, :LOCKFILE_PATH)
    namespace.const_set(:LOCKFILE_PATH, lockfile_path)
    namespace.const_set(:Time, Class.new do
      def self.now
        Time.utc(2026, 1, 1)
      end

      def self.iso8601(value)
        Time.iso8601(value)
      end
    end)

    namespace.const_get(:RubyTemplate)
  end

  let(:vendor_class) do
    metadata = [{ "number" => "1.1.0", "created_at" => created_at }]
    metadata_failure = metadata_error
    client = Class.new do
      define_method(:versions) do |_name|
        raise metadata_failure if metadata_failure

        metadata
      end
    end
    vendor_module.send(:remove_const, :RubyGemsClient)
    vendor_module.const_set(:RubyGemsClient, client)

    recorded_commands = commands
    resolved_lockfile = updated_lockfile
    target = lockfile_path
    cache_failure = cache_error
    Class.new(vendor_module.const_get(:Vendor)) do
      define_method(:run_command) do |command|
        recorded_commands << command
        File.write(target, resolved_lockfile) if command[1] == "lock"
        raise cache_failure if command[1] == "cache" && cache_failure
      end
    end
  end

  it "keeps the default lock command and caches accepted versions" do
    result = nil
    expect { result = vendor_class.new(argv: []).run }.to output.to_stdout

    expect(result).to eq(0)
    expect(commands).to eq([
                             %w[bundle lock --add-checksums],
                             %w[bundle cache --all-platforms --no-install]
                           ])
  end

  it "updates the full lockfile before caching versions that pass cooldown" do
    result = nil
    expect { result = vendor_class.new(argv: ["--update"]).run }.to output.to_stdout

    expect(result).to eq(0)
    expect(commands).to eq([
                             %w[bundle lock --update --add-checksums],
                             %w[bundle cache --all-platforms --no-install]
                           ])
    expect(File.read(lockfile_path)).to eq(updated_lockfile)
  end

  context "when an updated version has not passed cooldown" do
    let(:created_at) { "2026-01-01T00:00:00Z" }

    it "restores the original lockfile without caching" do
      result = nil
      expect do
        expect { result = vendor_class.new(argv: ["--update"]).run }.to output.to_stdout
      end.to output(/RubyGems cooldown rejected/).to_stderr

      expect(result).to eq(1)
      expect(commands).to eq([%w[bundle lock --update --add-checksums]])
      expect(File.read(lockfile_path)).to eq(original_lockfile)
    end
  end

  context "when fetching metadata fails" do
    let(:metadata_error) { vendor_module.const_get(:VendorError).new("metadata unavailable") }

    it "restores the original lockfile without caching" do
      result = nil
      expect do
        expect { result = vendor_class.new(argv: ["--update"]).run }.to output.to_stdout
      end.to output(/metadata unavailable/).to_stderr

      expect(result).to eq(1)
      expect(commands).to eq([%w[bundle lock --update --add-checksums]])
      expect(File.read(lockfile_path)).to eq(original_lockfile)
    end
  end

  context "when fetching metadata raises an unhandled error" do
    let(:metadata_error) { IOError.new("connection closed") }

    it "restores the original lockfile before propagating the error" do
      expect do
        expect do
          expect { vendor_class.new(argv: ["--update"]).run }.to raise_error(IOError, "connection closed")
        end.to output.to_stdout
      end.to output(/Gemfile.lock was restored/).to_stderr

      expect(commands).to eq([%w[bundle lock --update --add-checksums]])
      expect(File.read(lockfile_path)).to eq(original_lockfile)
    end
  end

  context "when caching fails after cooldown validation" do
    let(:cache_error) { vendor_module.const_get(:VendorError).new("cache unavailable") }

    it "keeps the validated lockfile" do
      result = nil
      expect do
        expect { result = vendor_class.new(argv: ["--update"]).run }.to output.to_stdout
      end.to output("cache unavailable\n").to_stderr

      expect(result).to eq(1)
      expect(commands.last).to eq(%w[bundle cache --all-platforms --no-install])
      expect(File.read(lockfile_path)).to eq(updated_lockfile)
    end
  end
end
