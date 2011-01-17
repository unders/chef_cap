require "json"
require "erb"
require "fileutils"

class ChefDnaParser

  class << self
    attr_accessor :dna, :parsed, :file_path, :test_dna
    
    def test_dna=(json)
      @test_dna = json
    end
    
    def load_dna
      @parsed ||= {}
      @dna ||= ""
      if @test_dna
        @dna = ERB.new(@test_dna).result(binding)
      else
        @file_path = ENV["DNA"] || ENV["dna"] || default_dna_path
        
        @dna = ERB.new(File.read(file_path)).result(binding)
      end
      @parsed = JSON.parse(@dna)
    end

    def default_dna_path
      File.join(rails_root, "chef", "node.json")
    end

    def rails_root
      FileUtils.pwd
    end
  end

end