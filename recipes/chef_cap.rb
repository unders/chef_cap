require File.expand_path(File.join(File.dirname(__FILE__), "lib", "chef_dna_parser"))
require File.expand_path(File.join(File.dirname(__FILE__), "lib", "chef_cap_helper"))
require File.expand_path(File.join(File.dirname(__FILE__), "lib", "chef_cap_configuration"))
require File.expand_path(File.join(File.dirname(__FILE__), "lib", "chef_cap_initializer"))

class DnaConfigurationError < Exception; end

ChefCapConfiguration.configuration = self
ChefDnaParser.load_dna

before "deploy", "chef:setup"

set :application, ChefDnaParser.parsed["application"]["name"] rescue nil
set :repository, ChefDnaParser.parsed["application"]["repository"] rescue nil

ChefCapConfiguration.set_repository_settings

if ChefDnaParser.parsed["environments"]
  if environment_defaults = ChefDnaParser.parsed["environments"]["defaults"]
    ChefCapHelper.parse_hash(environment_defaults)
  end

  set :environments, {}

  ChefDnaParser.parsed["environments"].each_key do |environment|
    next if environment == "default"
    environment_hash = ChefDnaParser.parsed["environments"][environment]

    set :environments, environments.merge(environment => environment_hash)

    desc "Set server roles for the #{environment} environment"
    task environment.to_sym do
      set :environment_settings, environment_hash
      set :rails_env, environment_hash["rails_env"] || environment
      set :role_order, environment_hash["role_order"] || {}
      default_environment["RAILS_ENV"] = rails_env

      ChefCapHelper.parse_hash(environment_hash)

      (environment_hash["servers"] || []).each do |server|
        if server["roles"] && server["hostname"]
          server["roles"].each do |role|
            options = {}
            options[:primary] = true if server["primary"] && server["primary"].include?(role)
            role role.to_sym, server["hostname"], options
          end
        end
      end
    end
    after environment.to_sym, "ssh:set_options"
  end
end

namespace :ssh do
  desc "Transfer SSH keys to the remote server"
  task :transfer_keys do
    private_key = ssh_deploy_key_file rescue false
    public_key = ssh_authorized_pub_file rescue false
    known_hosts = ssh_known_hosts rescue false
    if private_key || public_key || known_hosts
      private_key_remote_file = ".ssh/id_rsa"
      if private_key
        key_contents = File.read(private_key)
        private_key_remote_file = ".ssh/id_dsa" if key_contents =~ /DSA/i
      end
      run "mkdir -p ~/.ssh"
      if private_key
        put(File.read(private_key), private_key_remote_file, :mode => "0600")
      end
      put(File.read(public_key), ".ssh/authorized_keys", :mode => "0600") if public_key
      put(known_hosts, ".ssh/known_hosts", :mode => "0600") if known_hosts
    end
    depend(:remote, :file, private_key_remote_file) if private_key
    depend(:remote, :file, ".ssh/authorized_keys") if public_key
    depend(:remote, :file, ".ssh/known_hosts") if known_hosts
  end

  desc "Set any defined SSH options"
  task :set_options do
    ssh_options[:paranoid] = ssh_options_paranoid rescue nil
    ssh_options[:keys] = ssh_options_keys rescue nil
    ssh_options[:forward_agent] = ssh_options_forward_agent rescue nil
    ssh_options[:username] = ssh_options_username rescue user rescue nil
    ssh_options[:port] = ssh_options_port rescue nil
  end
end
before "chef:setup", "ssh:transfer_keys"
before "ssh:transfer_keys", "ssh:set_options"

if ChefDnaParser.parsed["upload"]
  uploads_for_roles = {}
  ChefDnaParser.parsed["upload"].each do |upload|
    unless upload.has_key?("source") && upload.has_key?("destination") && upload.has_key?("roles")
      raise DnaConfigurationError, "Invalid upload entry, should be {'source':value, 'destination':value, 'roles':[list], 'mode':value}"
    end
    upload["roles"].each do |role|
      uploads_for_roles[role] ||= []
      uploads_for_roles[role] << [upload["source"], upload["destination"], {:mode => upload["mode"] || "0644"}]
    end
  end

  uploads_for_roles.each_pair do |role, file_uploads|
    task "chef_upload_for_#{role}".to_sym, :roles => role do
      file_uploads.each do |file_to_upload|
        # TODO: better then mac local -> linux remote compatibility here
        run "md5sum #{file_to_upload[1]} | cut -f1 -d ' '" do |channel, stream, data|
          remote_md5 = data.to_s.strip
          local_md5 = `md5 #{file_to_upload[0]} | cut -f 2 -d '='`.to_s.strip
          if remote_md5 == local_md5
            puts "#{File.basename(file_to_upload[1])} matches checksum, skipping"
          else
            upload file_to_upload[0], file_to_upload[1], :host => channel[:host]
          end
        end
      end
    end
  end

  namespace :chef do
    desc "Uploads specified files to remote server"
    task :upload_all do
      uploads_for_roles.keys.each do |role|
        send "chef_upload_for_#{role}".to_sym
      end
    end
  end

  before "chef:deploy", "chef:upload_all"
end

if ChefDnaParser.parsed["chef"] && ChefDnaParser.parsed["chef"]["root"]
  set :chef_root_path, ChefDnaParser.parsed["chef"]["root"]
elsif ChefDnaParser.file_path
  default_chef_path = File.expand_path(File.join(File.dirname(ChefDnaParser.file_path)))
  if File.directory?(File.join(default_chef_path, "cookbooks"))
    set :chef_root_path, default_chef_path
  end
else
  raise DnaConfigurationError, "Could not find cookbooks in JSON or as a subdirectory of where your JSON is!"
end

if ChefDnaParser.parsed["chef"] && ChefDnaParser.parsed["chef"]["version"]
  set :chef_version, ChefDnaParser.parsed["chef"]["version"]
else
  default_chef_version = "0.9.16"
  set :chef_version, default_chef_version
end

set :rvm_bin_path, "/tmp/.chef_cap_rvm_path"

namespace :chef do
  desc "Setup chef solo on the server(s)"
  task :setup do
    gem_check_for_chef_cmd = "gem specification --version '>=#{chef_version}' chef 2>&1 | awk 'BEGIN { s = 0 } /^name:/ { s = 1; exit }; END { if(s == 0) exit 1 }'"
    install_chef_cmd = "sudo `cat #{rvm_bin_path}` default exec gem install chef --no-ri --no-rdoc"
    sudo "`cat #{rvm_bin_path}` default exec #{gem_check_for_chef_cmd} || #{install_chef_cmd} && echo 'Chef Solo already on this server.'"
    sudo "`cat #{rvm_bin_path}` default exec which chef-solo"
  end

  desc "Run chef-solo on the server(s)"
  task :deploy do
    put "cookbook_path '/tmp/chef-cap-#{rails_env}/cookbooks'", "/tmp/chef-cap-solo-#{rails_env}.rb", :mode => "0600"
    sudo "rm -rf /tmp/chef-cap-#{rails_env}"
    upload chef_root_path, "/tmp/chef-cap-#{rails_env}", :mode => "0700"


    begin
      env_settings = environment_settings
    rescue
      raise "Could not load environment_settings, usually this means you tried to run the deploy task without calling an <env> first"
    end
    parallel do |session|
      session.else "echo 'Deploying Chef to this machine'" do |channel, stream, data|
        roles_for_host = ChefCapHelper.roles_for_host(roles, channel[:host])

        json_to_modify = ChefDnaParser.parsed.dup
        hash_for_host = ChefCapHelper.merge_roles_for_host(json_to_modify["roles"], roles_for_host)

        shared_hash = json_to_modify["shared"] || {}
        shared_hash.each { |k, v| ChefCapHelper.recursive_merge(json_to_modify, k, v) }
        hash_for_host.each {|k, v| ChefCapHelper.recursive_merge(json_to_modify, k, v) }

        json_to_modify["environment"] ||= json_to_modify["environments"]["defaults"] || {} rescue {}
        env_settings.each { |k, v| ChefCapHelper.recursive_merge(json_to_modify["environment"] || {}, k, v) }

        json_to_modify["environment"]["roles"] = roles_for_host
        json_to_modify["environment"]["revision"] = ChefCapHelper.set_revision if ChefCapHelper.has_revision?
        json_to_modify["environment"]["branch"] = ChefCapHelper.set_branch if ChefCapHelper.has_branch?
        json_to_modify["environment"]["servers"] = ChefCapHelper.intialize_primary_values(json_to_modify["environment"]["servers"])

        should_not_deploy = no_deploy rescue false
        json_to_modify["run_list"] = ChefCapHelper.rewrite_run_list_for_deploy(json_to_modify, should_not_deploy)

        set "node_hash_for_#{channel[:host].gsub(/\./, "_")}", json_to_modify
        put json_to_modify.to_json, "/tmp/chef-cap-#{rails_env}-#{channel[:host]}.json", :mode => "0600"
      end
    end

    chef.run_chef_solo
  end

  task :run_chef_solo do
    debug_flag = ENV['QUIET'] ? '' : '-l debug'
    run_chef_solo = "env PATH=$PATH:/usr/sbin `cat #{rvm_bin_path}` default exec chef-solo -c /tmp/chef-cap-solo-#{rails_env}.rb -j /tmp/chef-cap-#{rails_env}-`hostname`.json #{debug_flag}"

    unless role_order.empty?
      role_order.each do |role, dependent_roles|
        role_hosts = find_servers(:roles => [role.to_sym]).map(&:host)
        dependent_hosts = find_servers(:roles => dependent_roles.map(&:to_sym)).map(&:host) - role_hosts

        sudo(run_chef_solo, :hosts => role_hosts) if role_hosts.any?
        sudo(run_chef_solo, :hosts => dependent_hosts) if dependent_hosts.any?
      end
    else
      sudo(run_chef_solo)
    end

  end

  desc "Remove all chef-cap files from /tmp"
  task :cleanup do
    sudo "rm -rf /tmp/chef-cap*"
  end
end

before "chef:deploy", "chef:setup"
