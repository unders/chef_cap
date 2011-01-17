class ChefCapConfiguration
  class << self
    attr_accessor :configuration

    def set_repository_settings
      repository_value = @configuration.send(:repository) rescue false
      case repository_value
        when /git/
          @configuration.send(:set, :scm, :git)
          @configuration.send(:set, :git_enable_submodules, 1)
          @configuration.send(:default_run_options)[:pty] = true
          @configuration.send(:depend, :remote, :command, "git")
        when /svn/
          @configuration.send(:set, :scm, :svn)
          @configuration.send(:depend, :remote, :command, "svn")
      end
    end
  end
end