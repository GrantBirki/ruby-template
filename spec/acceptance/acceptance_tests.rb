# frozen_string_literal: true

require "json"
require "open3"
require "rspec"

MAX_WAIT_TIME = 30 # how long to wait for the container to complete

APP_NAME = "ruby-template"
CI = ENV.fetch("CI", "false") == "true"

def docker_output(*args)
  stdout, stderr, status = Open3.capture3("docker", *args)
  return stdout if status.success?

  raise "docker #{args.join(' ')} failed: #{stderr}"
end

def container_status
  JSON.parse(docker_output("inspect", APP_NAME)).fetch(0).fetch("State").fetch("Status")
end

def container_logs
  docker_output("logs", APP_NAME)
end

describe "ruby-template" do
  before(:all) do
    # wait for the container's state to be "exited"
    start_time = Time.now
    while container_status != "exited"
      if Time.now - start_time > MAX_WAIT_TIME
        puts docker_output("inspect", APP_NAME)
        raise "Container did not exit within #{MAX_WAIT_TIME} seconds"
      end

      if CI
        puts "container inspect: #{docker_output('inspect', APP_NAME)}"
        puts "container logs: #{container_logs}"
      end

      sleep 1
    end
  end

  it "checks the logs of the container" do
    expect(container_logs).to include("3")
  end
end
