
require "bundler/gem_tasks"
require 'rspec/core/rake_task'

task :default => :test

# RSpec tests
RSpec::Core::RakeTask.new :test

task :release_gem => :install do
  system "gem push pkg/*.gem"
end

task :g  => :install
task :gp => :release_gem
