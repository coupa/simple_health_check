# config is a hash that has the redis config details such as host, port and password
class SimpleHealthCheck::RedisCheck < SimpleHealthCheck::BaseNoProc
  def initialize service_name: 'redis', check_proc: nil, config: {}
    @service_name = service_name
    @proc = check_proc || SimpleHealthCheck::Configuration.redis_check_proc
    @type = 'internal'
    config = config.symbolize_keys
    @host = config[:host]
    @port = config[:port] || 6379
    @password = config[:password] || ''
  end

  def call(response:)
    super do
      raise "Redis host is empty. Please pass the config correctly" if @host.blank?

      redis_client = ::Redis.new(host: @host, port: @port, password: @password)
      @version = redis_client.info['redis_version'] rescue nil
      res = redis_client.ping
      res == 'PONG' ? true : (raise "Redis.ping returned #{res.inspect} instead of PONG")
    end
  end
end
