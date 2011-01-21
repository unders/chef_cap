require File.expand_path(File.join(File.dirname(__FILE__), "chef_cap/version"))

module ChefCap

  class Capistrano
    RECIPES_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", "recipes"))

    def self.load_recipes(capistrano)
      Dir[File.join(RECIPES_PATH, "*.rb")].each { |recipe| capistrano.send(:load, recipe) }
    end

  end

end