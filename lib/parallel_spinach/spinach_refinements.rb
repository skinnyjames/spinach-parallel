module SpinachRefinements
  refine Spinach::Runner do 
    def run_with
      require_dependencies
      require_frameworks
      init_reporters

      suite_passed = true

      Spinach.hooks.run_before_run
      
      suite_passed = yield if block_given?

      Spinach.hooks.run_after_run(suite_passed)

      suite_passed
    end
  end
end


module Spinach
  class Runner
  end
end
