require "rubygems"
require "rspec"
require "json"

require File.expand_path(File.join(File.dirname(__FILE__), "..", "recipes", "lib", "chef_dna_parser"))
require File.expand_path(File.join(File.dirname(__FILE__), "..", "recipes", "lib", "chef_cap_helper"))
require File.expand_path(File.join(File.dirname(__FILE__), "..", "recipes", "lib", "chef_cap_configuration"))

class TestCapConfiguration < Object; attr_accessor :test_dna, :tasks; end
class TestCapSession < Object; end
class TestCapRole < Object; end
class TestCapServer < Struct.new(:host); end
class TestCapMockNamespace < Object; attr_accessor :configuration; end

class FakeChefCapConfiguration

  def self.create(dna)
    chef_cap_file = File.join(File.dirname(__FILE__), "..", "recipes", "chef_cap.rb")
    chef_cap_mock_file = File.join(File.dirname(__FILE__), "chef_cap_mock_cap.rb")

    fake_configuration = TestCapConfiguration.new
    ChefDnaParser.test_dna = dna
    fake_configuration.instance_eval(File.read(chef_cap_mock_file), chef_cap_mock_file)

    Dir[File.join(File.dirname(__FILE__), "..", "recipes", "*.rb")].each do |file|
      fake_configuration.instance_eval(File.read(file), file)
    end
    fake_configuration.tasks.each do |task_name, the_proc|
      fake_configuration.class.class_eval do
        define_method task_name.to_sym do
          the_proc.call
        end
      end
    end
    fake_configuration
  end

end

RSpec.configure do |config|
  config.mock_with :rspec
  config.after :each do
    ChefDnaParser.test_dna = nil
  end
end
