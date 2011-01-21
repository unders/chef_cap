require 'rubygems'

# Set up gems listed in the Gemfile.
gemfile = File.expand_path('Gemfile', __FILE__)
begin
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'
  Bundler.setup
rescue Bundler::GemNotFound => e
  STDERR.puts e.message
  STDERR.puts "Try running `bundle install`."
  exit!
end if File.exist?(gemfile)
require File.join(File.dirname(__FILE__), "lib/chef_cap")
load 'deploy' if respond_to?(:namespace) # cap2 differentiator
::ChefCap::Capistrano.load_recipes(self)
