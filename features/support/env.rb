require "rspec"
require_relative "../../lib/parallel_spinach/reporter"
require "rest-client"
Spinach::Reporter::Parallel.on_finished do |scenarios|
  pp scenarios
end

class Spinach::FeatureSteps
  include RSpec::Matchers
end