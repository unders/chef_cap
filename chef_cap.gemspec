# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "chef_cap/version"

Gem::Specification.new do |s|
  s.name        = "chef_cap"
  s.version     = ChefCap::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Case Commons, LLC"]
  s.email       = ["casecommons-dev@googlegroups.com"]
  s.homepage    = "https://github.com/Casecommons/chef_cap"
  s.license     = "MIT"
  s.add_dependency('capistrano', '>= 2.5.5')
  s.summary     = %q{capistrano + chef-solo == chef_cap"}
  s.description = %q{chef_cap uses chef"s JSON config format to drive both capistrano and chef-solo"}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
