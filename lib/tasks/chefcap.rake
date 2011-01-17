namespace :chefcap do
  desc "Initialize chefcap JSON and cookbooks for the first time"
  task :initialize => :environment do
    require "fileutils"

    if File.exist?(Rails.root + "chef/node.json") || File.directory?(Rails.root + "chef/cookbooks")
      puts "Already initialized?"
    else
      FileUtils.mkdir_p(Rails.root + "chef")
      FileUtils.cp_r Dir.glob(File.join(File.dirname(__FILE__), "example", "*")), (Rails.root + "chef")
    end
  end
end