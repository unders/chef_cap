require File.expand_path(File.join(File.dirname(__FILE__), "spec_helper"))

describe ChefCapConfiguration do
  describe ".set_repository_settings" do
    it "should set repository values for a git repository" do
      configuration = mock("Configuration")
      configuration.stub!(:repository => "git@somegitrepo")
      configuration.should_receive(:set).with(:scm, :git)
      configuration.should_receive(:set).with(:git_enable_submodules, 1)
      configuration.should_receive(:default_run_options).and_return({})
      configuration.should_receive(:depend).with(:remote, :command, "git")
      ChefCapConfiguration.configuration = configuration

      ChefCapConfiguration.set_repository_settings
    end

    it "should set repository values for an svn repository" do
      configuration = mock("Configuration")
      ChefCapConfiguration.configuration = configuration
      configuration.stub!(:repository => "svn://somesvnrepo")
      configuration.should_receive(:set).with(:scm, :svn)
      configuration.should_receive(:depend).with(:remote, :command, "svn")

      ChefCapConfiguration.set_repository_settings
    end
  end
end
