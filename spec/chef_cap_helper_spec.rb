require File.expand_path(File.join(File.dirname(__FILE__), "spec_helper"))

describe ChefDnaParser do

  describe ".recursive_merge" do

    it "assigns a key value if the original has does not have the key" do
      original_hash = {}

      resulting_hash = ChefCapHelper.recursive_merge(original_hash, "newkey", "somevalue")
      resulting_hash["newkey"].should == "somevalue"
    end

    it "overwrites a value with the new value if there is a type mismatch" do
      original_hash = {"key" => "value"}

      resulting_hash = ChefCapHelper.recursive_merge(original_hash, "key", 1)
      resulting_hash["key"].should == 1
      resulting_hash = ChefCapHelper.recursive_merge(original_hash, "key", ["value"])
      resulting_hash["key"].should == ["value"]
      resulting_hash = ChefCapHelper.recursive_merge(original_hash, "key", {:key => :value})
      resulting_hash["key"].should == {:key => :value}
      resulting_hash = ChefCapHelper.recursive_merge(original_hash, "key", nil)
      resulting_hash["key"].should be_nil
    end

    it "uniquely merges the values of two arrays" do
      original_hash = {"key" => ["original", "duplicate"]}

      resulting_hash = ChefCapHelper.recursive_merge(original_hash, "key", ["duplicate", "newvalue"])
      resulting_hash["key"].should =~ ["original", "duplicate", "newvalue"]
    end

    it "merges arrays of arrays" do
      original_hash = {"key" => ["one", ["two", "three"]]}

      resulting_hash = ChefCapHelper.recursive_merge(original_hash, "key", ["onepointfive", ["two", "three"]])
      resulting_hash["key"].should =~  ["one", "onepointfive", ["two", "three"]]
    end

    it "merges keys and values of hashes" do
      original_hash = {"key" => { "one" => "two" }}

      resulting_hash = ChefCapHelper.recursive_merge(original_hash, "key", {"one" => "nottwo"})
      resulting_hash["key"].should == { "one" => "nottwo" }
      resulting_hash = ChefCapHelper.recursive_merge(original_hash, "key", {"one" => nil})
      resulting_hash["key"].should == { "one" => nil }
    end

    it "merge will overwrite hashes with arrays" do
      original_hash = {"key" => {"array" => ["one"] }}

      resulting_hash = ChefCapHelper.recursive_merge(original_hash, "key", {"array" => ["two", "three"]})
      resulting_hash["key"].should == {"array" => ["two", "three"]}
    end

  end

  describe ".roles_for_host" do
    it "returns the list of roles that match for a given host" do
      otherserver = stub("Server", :host => "somehostname")
      matchserver = stub("Server", :host => "myhostname")

      roles = { :matchrole => stub("Role", :servers => [otherserver, matchserver]),
                :otherrole => stub("Role", :servers => [otherserver])}
      ChefCapHelper.roles_for_host(roles, "myhostname").should == ["matchrole"]
    end
  end

  describe ".merge_roles_for_host" do
    it "merges the run list if the host has multiple roles" do
      roles_hash = {
        "role1" => {
          "something else" => "yes",
          "run_list" => ["role1run"]
        },
        "role2" => {
          "something else" => "yup",
          "run_list" => ["role1run, role2run"]
        },
        "role3" => {
          "something else" => "nope",
          "run_list" => ["role3run"]
        }
      }

      ChefCapHelper.merge_roles_for_host(roles_hash, ["role1", "role2"]).should == {"run_list"=>["role1run", "role1run, role2run"], "something else"=>"yup"}
    end

    it "returns empty hash" do
      ChefCapHelper.merge_roles_for_host(nil, ["role1", "role2"]).should == {}
    end
  end

  describe ".rewrite_run_list_for_deploy" do
    it "should move the deploy recipe to the end of the run list if it is specified" do
      json_with_run_list = {
        "run_list" => ["something", "something", "deployrecipe", "darkside"],
        "deploy_recipe" => "deployrecipe"
      }

      ChefCapHelper.rewrite_run_list_for_deploy(json_with_run_list).should == ["something", "something", "darkside", "deployrecipe"]
    end

    it "should do nothing if the run list does not contain the deploy recipe" do
      json_with_run_list = {
        "run_list" => ["something", "something", "darkside"],
        "deploy_recipe" => "deployrecipe"
      }

      ChefCapHelper.rewrite_run_list_for_deploy(json_with_run_list).should == ["something", "something", "darkside"]
    end
  end

  describe ".intialize_primary_values" do
    it "should make sure each server has a primary key with a value of empty array of it has nothing" do
      array_of_servers_hash = [
        { "host" => "server1"}
        ]
      ChefCapHelper.intialize_primary_values(array_of_servers_hash).should == [{"host" => "server1", "primary" => []}]
    end

    it "should not touch the setting of a server if it already has a value" do
      array_of_servers_hash = [
        { "host" => "server1", "primary" => ["one", "two"]}
        ]
      ChefCapHelper.intialize_primary_values(array_of_servers_hash).should == array_of_servers_hash
    end
  end

  describe ".set_revision" do
    ["rev", "tag", "revision"].each do |word|
      [word, word.upcase, "-S#{word}"].each do |variable|
        it "returns the value of ENV['#{variable}']" do
          value = Time.now.to_f.to_s
          ENV["#{variable}"] = value
          ChefCapHelper.set_revision.should == value
        end

        after :each do
          ENV["#{variable}"] = nil
        end
      end
    end
  end

  describe ".set_branch" do
    ["branch", "BRANCH", "-Sbranch"].each do |variable|
      it "returns the value of ENV['#{variable}']" do
        value = Time.now.to_f.to_s
        ENV["#{variable}"] = value
        ChefCapHelper.set_branch.should == value
      end

      after :each do
        ENV["#{variable}"] = nil
      end
    end
  end

end
