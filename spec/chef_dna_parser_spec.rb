require File.expand_path(File.join(File.dirname(__FILE__), "spec_helper"))

describe ChefDnaParser do
  describe ".load_dna" do

    it "parses test dna with ERB" do
      ChefDnaParser.test_dna = <<-JS
        {
          "some_key": "some_value <%= ENV['HOME'] %>"
        }
      JS

      ChefDnaParser.load_dna
      ChefDnaParser.parsed.should_not be_nil
      ChefDnaParser.parsed["some_key"].should_not be_nil
      ChefDnaParser.parsed["some_key"].should == "some_value #{ENV['HOME']}"
    end
    
    it "parses dna from file using environment variable" do
      ENV["DNA"] = File.expand_path(File.join(File.dirname(__FILE__), "..", "fixtures", "parser.json"))
      ChefDnaParser.load_dna
      ChefDnaParser.parsed.should_not be_nil
      ChefDnaParser.parsed["from_file_key"].should_not be_nil
      ChefDnaParser.parsed["from_file_key"].should == "from_file_value"
    end
    
  end

end