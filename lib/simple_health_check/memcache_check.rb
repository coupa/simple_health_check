# `config` is an array of memcached server details such as [localhost:11211] or [localhost:11211:0, secondary:11211:5]
class SimpleHealthCheck::MemcacheCheck < SimpleHealthCheck::BaseNoProc

  def initialize service_name: 'memcache', check_proc: nil, config: []
    @service_name = service_name
    @proc = check_proc || SimpleHealthCheck::Configuration.memcache_check_proc
    @type = 'internal'
    @memcache_servers = config
  end

  def call(response:)
    super do
      unless defined?(::Dalli::Client)
        raise "Dalli gem not found! Could not find the healthcheck of memcached servers."
      end
      # Memcached servers will be of the form  localhost:11211 or secondary:11211:5. Added length == 1 condition in case config is not set properly
      raise "Please pass the memcache config correctly" if @memcache_servers.empty? || @memcache_servers.any? {|server| server.split(':').length == 1}

      dalli_client = ::Dalli::Client.new(@memcache_servers)
      @version = dalli_client.version&.values rescue nil
      dalli_client.alive!
    end
  end
end
