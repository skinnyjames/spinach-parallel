# spinach-parallel
testing spinach in parallel with aggregation
[![Build Status](http://drone.skinnyjames.net/api/badges/skinnyjames/spinach-parallel/status.svg)](http://drone.skinnyjames.net/skinnyjames/spinach-parallel)

env.rb

```ruby
Spinach::Reporter::Parallel.on_finished do |scenarios|
  pp scenarios
end
```

drone.yml
```yaml
kind: pipeline
name: default
type: kubernetes

steps:
- name: redis
  image: redis
  detach: true

- name: agent_1
  image: ruby:3.0
  commands: 
    - bundle install
    - gem install knapsack
    - EXPECTED_AGENTS=2 DOUBLE_DECKER_RUN_ID=test ruby lib/parallel_spinach.rb -r parallel
  depends_on: 
    - redis

- name: agent_2
  image: ruby:3.0
  commands: 
    - bundle install
    - gem install knapsack
    - EXPECTED_AGENTS=2 DOUBLE_DECKER_RUN_ID=test ruby lib/parallel_spinach.rb -r parallel
  depends_on: 
    - redis
```
