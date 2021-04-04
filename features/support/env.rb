require "rspec"
require "double_decker"
require_relative "../../lib/parallel_spinach/reporter"

Spinach::Reporter::Parallel.on_finished do |scenarios|
  pp scenarios
end

class Spinach::FeatureSteps
  include RSpec::Matchers
end