
require 'rspec/core/rake_task'

task :default => :test

# RSpec tests
RSpec::Core::RakeTask.new :test

task :build do
  system "rm -f *.gem"
  system "rm -rf pkg && mkdir pkg"
  system "gem build *.gemspec"
  system "mv *.gem pkg/"
end

task :g => :install
task :install => :build do
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

namespace :codegen do
  task :ffi do
    require_relative 'codegen/ffi'
  end
end
