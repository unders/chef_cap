desc "Run chef without deploy"
task :cook do
  set :no_deploy, true
  chef.deploy
end

before "cook", "chef:setup"
