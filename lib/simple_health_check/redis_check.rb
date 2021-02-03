# config is a hash that has the redis config details such as host, port and password
class SimpleHealthCheck::RedisCheck < SimpleHealthCheck::BaseNoProc
  DEFAULT_PORT = 6379
  
  def initialize service_name: 'redis', check_proc: nil, config: {}
    @service_name = service_name
    @proc = check_proc || SimpleHealthCheck::Configuration.redis_check_proc
    @type = 'internal'
    @config = config.symbolize_keys
  end

  def call(response:)
    super do
      raise "Redis host is empty. Please pass the config correctly" if @config[:host].blank? && @config[:cluster].blank?

      options = {
        port: @config[:port] || DEFAULT_PORT,
        password: @config[:password] || '',
        ssl: @config[:ssl] || false
      }

      if @config.key?(:cluster)
        options[:cluster] = @config[:host] || @config[:cluster]
      else
        options[:host] = @config[:host]
      end


      redis_client = ::Redis.new(options)
      @version = redis_client.info['redis_version'] rescue nil
      res = redis_client.ping
      res == 'PONG' ? true : (raise "Redis.ping returned #{res.inspect} instead of PONG")
    end
  end
end
