# Chef Cap

capistrano + chef-solo == deployment + server automation

Using chef's JSON configuration format to drive capistrano and chef-solo so you can use both to not only deploy your application but also completely automate the configuration of your servers.

## Documentation

# Steps to install

Add chef_cap to your gemfile:

    group :development do
      gem 'chef_cap'
    end

## Install the gem and then initialize:

    $ bundle install
    $ test -e Capfile || bundle exec capify .
    $ bundle exec rake chefcap:initialize

See the wiki for more detailed explanation of node.json and how it drives both capistrano and chef-solo.

# NOTICE

Chef and chef-solo are © 2010 Opscode (http://www.opscode.com/)
