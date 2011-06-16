depend :remote, :command, "rvm"
depend :remote, :command, "chef-solo"

before "chef:setup", "rvm:bootstrap"

namespace :rvm do
  desc "Create a standalone rvm installation with a default ruby to use with chef-solo"
  task :bootstrap do
    rvm_standup_script = <<-SH
      #!/bin/bash
      RVM_URL="https://rvm.beginrescueend.com/install/rvm"
      export PATH=$PATH:/usr/local/rvm/bin:~/.rvm/bin
      HAVE_RVM_ALREADY=`which rvm 2>/dev/null`
      if [ $? -eq 0 ]; then
        echo "Found RVM: " `which rvm`
        echo "Looks like RVM is already on this machine. Recording to /tmp/.chef_cap_rvm_path"
        which rvm > /tmp/.chef_cap_rvm_path
        exit 0
      else
        echo "Could not find RVM, PATH IS: ${PATH}"
        echo "Going to attempt to attempt to download and install RVM from ${RVM_URL}"
      fi

      HAVE_CURL=`which curl 2>/dev/null`
      if [ $? -eq 0 ]; then
        RVM_TEMP_FILE=`mktemp /tmp/rvm_bootstrap.XXXXXX`
        curl $RVM_URL > $RVM_TEMP_FILE
        chmod u+rx $RVM_TEMP_FILE
        sh $RVM_TEMP_FILE
        rm -f $RVM_TEMP_FILE
        which rvm > /tmp/.chef_cap_rvm_path
      else
        echo "FATAL ERROR: I have no idea how to download RVM without curl!"
        exit 1
      fi
    SH
    put rvm_standup_script, "/tmp/chef-cap-#{rails_env}-rvm-standup.sh", :mode => "0700"
    sudo "/tmp/chef-cap-#{rails_env}-rvm-standup.sh"
  end
end
