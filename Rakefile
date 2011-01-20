# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
require 'rake'
require 'rspec/core'
require 'rspec/core/rake_task'

require 'bundler'
Bundler::GemHelper.install_tasks

task :default => :spec

desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new(:spec)
