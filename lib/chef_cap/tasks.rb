require 'rake'

namespace :chef_cap do
  desc "Install chefcap JSON and cookbooks for the first time"
  task :install => :environment do
    require "fileutils"
    templates_path = File.join(File.dirname(__FILE__), "..", "generators", "chef_cap", "templates", "chef")

    FileUtils.cp_r File.join(templates_path, "..", "Capfile"), File.join(Rails.root, "Capfile")

    if File.exist?(Rails.root + "chef/node.json") || File.directory?(Rails.root + "chef/cookbooks")
      puts "Already initialized chef_cap?"
    else
      FileUtils.mkdir_p(Rails.root + "chef")
      FileUtils.cp_r Dir.glob(templates_path, "/*"), (Rails.root + "chef")
    end
  end
end
