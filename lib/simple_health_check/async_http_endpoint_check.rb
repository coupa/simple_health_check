# Usage:
# SimpleHealthCheck::AsyncHttpEndpointCheck.new(
#   [ 
#     {
#       name: 'abc',
#       hostname: lambda { Setup.lookup('test_hostname') },
#       enabled: lambda { Setup.key_enabled? },
#       health_path: '/health'
#     },
#     {
#       name: 'test',
#       hostname: 'abc-test.coupahost.com',
#       enabled: true,
#       health_path: '/v1/health'
#     }
#   ]
# ).call

class SimpleHealthCheck::AsyncHttpEndpointCheck < SimpleHealthCheck::Base
  # config is an array of hashes with the service names and http endpoints
  def initialize(config: [])
    @initial_configs = config.map(&:symbolize_keys)
  end

  def call(response:)
    # Refer: https://guides.rubyonrails.org/threading_and_code_execution.html
    Rails.application.executor.wrap do
      @configs = @initial_configs.select { |c| c[:enabled].respond_to?(:call) ? c[:enabled].call : c[:enabled] }
      futures = @configs.collect do |config|
        hostname = config[:hostname].respond_to?(:call) ? config[:hostname].call : config[:hostname]
        url = "#{hostname}#{config[:health_path]}"
        Concurrent::Future.execute do
          Rails.application.executor.wrap do
            obj = SimpleHealthCheck::HttpEndpointCheck.new(service_name: config[:name], url: url)
            {
              http_endpoint_obj: obj,
              response: obj.call(response: response)
            }
          end # executor.wrap
        end # Concurrent::Future.execute
      end # collect

      ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
        overall_responses = futures.collect(&:value)
        response.overall_status = overall_responses.all? {|a| a[:response][0] == :ok } ? :ok : :crit
        overall_responses
      end # interlock.permit_concurrent_loads
    end # executor.wrap

  end
end
