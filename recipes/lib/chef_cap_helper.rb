class ChefCapHelper
  class << self
    def debug(message)
      puts "** #{message}" if ENV["DEBUG"]
    end

    def parse_hash(hash, prefix = nil)
      hash.each do |key, value|
        if value.is_a? Hash
          parse_hash(value, [prefix, key].compact.join("_"))
        else
          key = [prefix, key].compact.join("_").to_sym
          debug("Setting #{key.inspect} => #{value.inspect}")
          ChefCapConfiguration.configuration.set key, value
        end
      end
    end

    def recursive_merge(hash, key, value)
      case "#{hash[key].class}_#{value.class}"
      when "Array_Array"
        hash[key] = hash[key] | value
      when "Hash_Hash"
        hash[key] = hash[key].merge(value)
      else
        hash[key] = value
      end
      hash
    end

    def roles_for_host(roles, current_host)
      roles.select do |role_name, role|
        role.servers.map(&:host).include?(current_host)
      end.map(&:first).map(&:to_s)
    end

    def merge_roles_for_host(roles_hash, roles_for_host)
      return {} if roles_hash.nil?

      merged_hash_for_host = {}
      roles_hash.each do |role_name, role_hash|
        if roles_for_host.include?(role_name.to_s)
          role_hash.each do |role_hash_key, role_hash_key_value|
            merged_hash_for_host.merge(recursive_merge(merged_hash_for_host, role_hash_key, role_hash_key_value))
          end
        end
      end
      merged_hash_for_host
    end

    def set_revision
      ["rev", "tag", "revision"].each do |word|
        [word, word.upcase, "-S#{word}"].each do |variable|
          return ENV[variable] if ENV[variable]
        end
      end
      nil
    end

    def set_branch
      ["branch", "BRANCH", "-Sbranch"].each do |variable|
        return ENV[variable] if ENV[variable]
      end
      nil
    end

    def has_branch?
      !set_branch.nil?
    end

    def has_revision?
      !set_revision.nil?
    end

    def rewrite_run_list_for_deploy(json_hash, should_not_deploy = false)
      return nil if json_hash["run_list"].nil?
      new_run_list = json_hash["run_list"].dup
      if json_hash.has_key? "deploy_recipe"
        deploy_recipe = new_run_list.delete(json_hash["deploy_recipe"])
        new_run_list << deploy_recipe if deploy_recipe && !should_not_deploy
      end
      new_run_list
    end

    def intialize_primary_values(array_of_server_hashes)
      array_of_server_hashes.each do |server_hash|
        server_hash["primary"] ||= []
      end
      array_of_server_hashes
    end

  end
end
