module ChefCap
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def install
        copy_file "Capfile", "Capfile"
        directory "chef/cookbooks/gems/recipes"
        copy_file "chef/node.json", "chef/node.json"
        copy_file "chef/cookbooks/gems/recipes/default.rb", "chef/cookbooks/gems/recipes/default.rb"
      end
    end
  end
end
