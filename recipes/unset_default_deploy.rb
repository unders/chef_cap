namespace :deploy do
  task :default do
    chef.deploy
  end

  task :long do
    # do nothing
  end

  task :update_code do
    # do nothing
  end

  task :finalize_update do
    # do nothing
  end

  task :symlink do
    # do nothing
  end

  task :restart do
    # do nothing
  end

  task :migrate do
    # do nothing
  end

  task :start do
    # do nothing
  end

  task :setup do
    # do nothing
  end
end

# Finally load deploy.rb if it exists and allow it to overwrite anything we've done here
unless File.exist?("config/deploy.rb")
  def load(*args)
    return true
  end
end
