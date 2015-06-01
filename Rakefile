
require 'rspec/core/rake_task'

task :default => :test

# RSpec tests
RSpec::Core::RakeTask.new :test

task :build do
  system "mkdir -p pkg && cd pkg && gem build ../*.gemspec"
end

task :g  => :install
task :install do
  system "gem install pkg/*.gem"
end

task :gp => :release
task :release => :install do
  system "gem push pkg/*.gem"
end

task :vendor do
  system "cd ext/rabbitmq && rake --trace"
end

task :vendor_clean do
  system "cd ext/rabbitmq && rake clean"
end
