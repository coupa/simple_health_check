class SimpleHealthCheck::HttpEndpointCheck < SimpleHealthCheck::BaseProc
  def initialize service_name: "http_endpoint", check_proc: nil
    @service_name = service_name
    @proc = check_proc || SimpleHealthCheck::Configuration.http_endpoint_check_proc
    @type = 'service'
  end

end
