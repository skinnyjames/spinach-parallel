require "spinach/cli"
require "spinach"
require "spinach/parser"
require "spinach/runner/scenario_runner"
require "double_decker"
require "gherkin_ruby"
module DoubleDecker
  class Queue
    
    attr_reader :run_id
    
    def initialize(run_id, store, *items)
      @run_id = run_id
      @store = store
      setup!(items)
    end

    def shift
      queue = JSON.parse(get)
      item = queue.shift
      commit(queue)
      item
    end

    def active?
      !!get
    end

    def empty?
      JSON.parse(get).empty?
    end

    def teardown!
      @store.del("#{run_id}_queue") if get
    end

    private

    def commit(queue)
      @store.set("#{run_id}_queue", queue.to_json)
    end

    def get
      @store.get("#{run_id}_queue")
    end

    def setup!(items)
      get || @store.set("#{run_id}_queue", items.to_json)
    end

  end

  class Bus
    def register_queue(*items)
      Queue.new(@run_id, @store, *items)
    end
  end
end

module Spinach
  class Runner
    def run_with
      require_dependencies
      require_frameworks
      init_reporters

      suite_passed = true

      Spinach.hooks.run_before_run
      
      yield if block_given?

      Spinach.hooks.run_after_run(suite_passed)

      suite_passed
    end
  end
end

module Splitter
  module Spinach
    class Cli
      def self.run(opts)
        cli = ::Spinach::Cli.new(opts)
        cli.options
        scenarios_paths = cli.feature_files.map do |file|
          feature = ::Spinach::Parser.open_file(file).parse
          feature.scenarios.map do |scenario|
            "#{file}:#{scenario.lines.join(":")}"
          end
        end.flatten

        bus = DoubleDecker::Bus.new(ENV["ID"])
        queue = bus.register_queue(*scenarios_paths)

        runner = ::Spinach::Runner.new([], cli.options)
        runner.run_with do 
          while queue.active? && !queue.empty?
            scenario_path, *lines = queue.shift.split(":")
            feature = ::Spinach::Parser::Visitor.new.visit GherkinRuby.parse(File.read(scenario_path) + "\n")
            feature.filename = scenario_path
            scenario_to_run = feature.scenarios.find do |s|
              s.lines.join(":").eql? lines.join(":")
            end
            ::Spinach::Runner::ScenarioRunner.new(scenario_to_run).run
          end
        end
        queue.teardown! 
      end
    end
  end
end

Splitter::Spinach::Cli.run(ARGV)