module Spinach
  class Reporter
    class Parallel < Spinach::Reporter
      def self.on_finished(&block)
        @finished = lambda do |payload|
          scenarios = payload.values.inject([]) do |arr, data|
            arr << data.values
          end.flatten
          block.call(scenarios) if block
        end
      end

      def self.finished
        @finished
      end

      def initialize(*args)
        super(*args)
        @out = options[:output] || $stdout
        @bus = DoubleDecker::Bus.new ENV["DOUBLE_DECKER_RUN_ID"], expected_agents: ENV["EXPECTED_AGENTS"]
        finished = Parallel.finished
        @bus.on_finished(&finished)
        @agent = @bus.register
        at_exit do
          @agent.finish!
        end
      end

      def before_scenario_run(scenario, feature)
        @report = {
          tags: scenario.tags,
          feature: scenario.feature.name,
          file_path: scenario.feature.filename,
          start_time: Time.now,
          status: 'PASSED'
        }
      end
          
      def on_failed_step(_, ex, _, _)
        @report[:status] = "FAILED"
        @report[:exception] = ex.to_s
      end
          
      def on_error_step(_, ex, _, _)
        @report[:status] = 'FAILED'
        @report[:exception] = ex.to_s
      end
          
      def on_skipped_step 
        @report[:status] = 'SKIPPED' unless @report[:status].eql?('FAILED')
      end
          
      def after_scenario_run(scenario, feature)
        end_time = Time.now
      
        @report[:end_time] = end_time
        @report[:duration] = @report[:end_time] - @report[:start_time]
            
        data = @agent.to_h
        data['scenarios'] ||= []
        data['scenarios'] << @report
        @agent.merge(data)
      end
    end
  end
end