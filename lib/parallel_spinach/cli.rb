require "spinach"
require "spinach/cli"
require "spinach/parser"
require "spinach/runner/scenario_runner"
require "double_decker"
require "gherkin_ruby"
require_relative "./double_decker_refinements"
require_relative "./spinach_refinements"

module Splitter
  module Spinach
    class Cli
      using SpinachRefinements

      def self.run(opts)
        cli = ::Spinach::Cli.new(opts)
        cli.options
        scenarios_paths = cli.feature_files.map do |file|
          feature = ::Spinach::Parser.open_file(file).parse
          feature.scenarios.map do |scenario|
            "#{file}:#{scenario.lines.join(":")}"
          end
        end.flatten

        bus = DoubleDecker::Bus.new(ENV["DOUBLE_DECKER_RUN_ID"])
        queue = bus.register_queue(*scenarios_paths)

        runner = ::Spinach::Runner.new([], cli.options)
        runner.run_with do 
          suite_passed = true
          while queue.active? && !queue.empty?
            scenario_path, *lines = queue.shift.split(":")
            feature = ::Spinach::Parser::Visitor.new.visit GherkinRuby.parse(File.read(scenario_path) + "\n")
            feature.filename = scenario_path
            scenario_to_run = feature.scenarios.find do |s|
              s.lines.join(":").eql? lines.join(":")
            end
            scenario_passed = ::Spinach::Runner::ScenarioRunner.new(scenario_to_run).run
            suite_passed &&= scenario_passed
            break if ::Spinach.config.fail_fast && !scenario_passed
          end
          suite_passed
        end
        queue.teardown! 
      end
    end
  end
end