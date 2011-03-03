def parent
  self
end

def namespace_objects
  @namespace_objects ||= {}
end

def default_environment
  @default_environment ||= {}
end

def find_servers(options = {})
  servers = []
  options[:roles].each do |role|
    if @servers && @servers.has_key?(role)
      @servers[role][:servers].each do |server|
        servers << TestCapServer.new(server)
      end
    else
      raise ArgumentError, "unknown role `#{role}'" unless roles.include?(role)
    end
  end
  servers
end

def task(name, *args)
  @tasks ||= {}
  @tasks[@curent_namespace ? "#{@curent_namespace}:#{name}" : name] = proc { yield }
  if @curent_namespace
    namespace_objects[@curent_namespace].instance_eval(<<-EOS)
      def #{name}
        configuration.cap_task["#{@current_namespace}:#{name}"]
      end
    EOS
  end
  @tasks
end

def cap_task
  @tasks ||= {}
end

def role(name, hostname, options = {})
  @servers ||= {}
  @servers[name] ||= {:servers => []}
  @servers[name][:servers] = @servers[name][:servers] << hostname
  @servers[name][:primary] = hostname if options[:primary]
end

def roles
  if JSON.parse(ChefDnaParser.test_dna)["roles"]
    role_hash = {}
    JSON.parse(ChefDnaParser.test_dna)["roles"].each_pair do |key, value|
      role_klass = TestCapRole.new

      role_klass.instance_eval(<<-EOS)
        def name
          #{key.inspect}
        end

        def servers
          []
        end
      EOS
      if cap_role.any?
        role_klass.instance_eval(<<-EOS)
          def servers
            role_servers = []
            #{cap_role[key.to_sym][:servers].inspect}.each do |server_hostname|
              host = TestCapServer.new
              host.instance_eval(<<-EOH)
                def host
                  \#{server_hostname.inspect}
                end
              EOH
              role_servers << host
            end
            role_servers
          end
        EOS
      end
      role_hash[key] = role_klass
    end
    role_hash
  else
    []
  end
end

def cap_role
  @servers ||= {}
end

def unset(key)
  @variables.delete(key)
  self.instance_eval(<<-EOS)
    undef #{key}
  EOS
end

def set(key, value)
  key.to_s.gsub!(/\.|-/, '_')
  self.instance_eval(<<-EOS)
    def #{key}
      #{value.inspect}
    end
  EOS
  @variables ||= {}
  @variables[key] = value
end

def cap_variable
  @variables ||= {}
end

def depend(local_or_remote, dependency_type, path)
  @dependencies ||= {}
  @dependencies[path] = { local_or_remote => dependency_type }
end

def cap_depends
  @dependencies ||= {}
end

def desc(message)
  @task_description = message
end

def current_description
  @task_description
end

def namespace(name, &block)
  @namespaces ||= {}
  @namespaces[name] = true
  @curent_namespace = name
  @namespace_objects ||= {}
  namespace_objects[name] = TestCapMockNamespace.new
  namespace_objects[name].configuration = self
  self.instance_eval(<<-EOS)
    def #{name}
      namespace_objects['#{name}'.to_sym]
    end
  EOS

  yield
ensure
  @curent_namespace = nil
end

def cap_namespace
  @namespaces ||= {}
end

def before(task_name, task_to_call, &block)
  @before_callchain ||= {}
  @before_callchain[task_name] ||= []
  @before_callchain[task_name] << task_to_call
end

def cap_before
  @before_callchain ||= {}
end

def after(task_name, task_to_call, &block)
  @after_callchain ||= {}
  @after_callchain[task_name] ||= []
  @after_callchain[task_name] << task_to_call
end

def ssh_options
  @ssh_options ||= {}
end

def cap_after
  @after_callchain ||= {}
end

def cap_ssh_options
  @ssh_options ||= {}
end

def default_run_options
  @default_run_options ||= {}
end

def parallel_sessions
  @parallel_sessions ||= []
end

def run(command, &block)
  @commands_run ||= {}
  if block_given?
    @commands_run[command] = proc { yield }
  else
    @commands_run[command] = true
  end
  @commands_run
end

def cap_run
  @commands_run ||= {}
end

def cap_servers
  cap_role.each_value.map do |hash|
    hash[:servers]
  end.flatten.uniq
end

def parallel_mocks
  @parallel_mocks ||= []
end

def parallel(options={})
  cap_servers.each do |server|
    session_klass = TestCapSession.new
    session_klass.instance_eval do
      def set_channel=(hash)
        @channel = hash
      end

      def channel
        @channel
      end

      def set_roles=(rolez)
        @roles = rolez
      end

      def roles
        @roles
      end

      def else(command, &block)
        instance_exec(channel, &block)
      end

      def set_environment_settings=(something)
        @env_settings = something
      end

      def environment_settings
        @env_settings
      end

      def set(key, value)
        @set ||= {}
        @set[key] = value
      end

      def things_that_were_set
        @set
      end

      def rails_env
        @set ||= {}
        @set[:rails_env]
      end

    end
    session_klass.set_channel = {:host => server}
    session_klass.set_roles = roles
    session_klass.set_environment_settings = cap_variable["environment_settings"]
    parallel_mocks.each do |mock|
      mock.call(session_klass)
    end
    @parallel_sessions ||= []
    @parallel_sessions << session_klass
    session_klass.instance_eval do
      yield session_klass
    end
  end
  @parallel_sessions
end
