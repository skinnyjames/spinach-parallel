require "rspec"
require "double_decker"

bus = DoubleDecker::Bus.new(ENV["ID"], expected_agents: ENV['CI_NODE_TOTAL'])

bus.on_finished do |payload|
  scenarios = payload.values.inject([]) do |arr, data|
    arr << data.values
  end.flatten
  pp scenarios.to_json
  File.open("test.json", "w") { |f| f << scenarios.to_json }
end

agent = bus.register

class Spinach::FeatureSteps
  include RSpec::Matchers
end

Spinach.hooks.before_scenario do |scenario, feature|
  @report = {
    tags: scenario.tags,
    feature: scenario.feature.name,
    file_path: scenario.feature.filename,
    start_time: Time.now,
    status: 'PASSED'
  }
end

Spinach.hooks.on_failed_step do |_, ex|
  @report[:status] = "FAILED"
  @report[:exception] = ex.to_s
end

Spinach.hooks.on_error_step do |_, ex|
  @report[:status] = 'FAILED'
  @report[:exception] = ex.to_s
end

Spinach.hooks.on_skipped_step do 
  @report[:status] = 'SKIPPED' unless @report[:status].eql?('FAILED')
end

Spinach.hooks.after_scenario do |scenario, feature|
  end_time = Time.now

  @report[:end_time] = end_time
  @report[:duration] = @report[:end_time] - @report[:start_time]

  puts @report

  data = agent.to_h
  data['scenarios'] ||= []
  data['scenarios'] << @report
  agent.merge(data)
end

at_exit do
  agent.finish!
end