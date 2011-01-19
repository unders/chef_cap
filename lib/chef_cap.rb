require "chef_cap/version"

module ChefCap
  module Rails
    class Railtie < ::Rails::Railtie
      rake_tasks do
        load "tasks/chefcap.rake"
      end
    end
  end
end
