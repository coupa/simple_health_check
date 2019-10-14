require 'simple_health_check/base'
require 'simple_health_check/base_proc'
require 'simple_health_check/base_no_proc'
require 'simple_health_check/basic_status_check'

module SimpleHealthCheck
  %w[
    generic_check
    simple_generic_check
    async_http_endpoint_check
    http_endpoint_check
    json_file
    mysql_check
    redis_check
    memcache_check
    resque_check
    scheduler_check
    s3_check
    version_check
    version
  ].each do |file|
    classified_string = file.split('_').collect!(&:capitalize).join
    autoload classified_string.to_sym, "simple_health_check/#{file}"
  end
end

require "simple_health_check/configuration"
require "simple_health_check/engine"

module SimpleHealthCheck
  class Response
    def initialize
      @body = {}
      @status = :ok
    end

    def add name:, status:
      @body[name] = status
    end

    def append json
      @body = @body.merge(json)
    end

    def overall_status
      @status
    end

    def overall_status= val
      @status = val if val != :ok
    end

    alias_method :status=, :overall_status=
    alias_method :status, :overall_status

    def body
      @body
    end
  end

  class << self
    def run_simple_checks
      response = SimpleHealthCheck::Response.new
      SimpleHealthCheck::Configuration.simple_checks.each_with_object(response) do |check, obj|
        begin
          check.call(response: obj)
        rescue # catch the error and try to log, but keep going finish all checks
          Rails.logger.error "simple_health_check gem ERROR: #{$ERROR_INFO}"
        end
      end
      response
    end

    def run_detailed_checks
      response = SimpleHealthCheck::Response.new
      unless SimpleHealthCheck::Configuration.detailed_description.nil?
        response.append(SimpleHealthCheck::Configuration.detailed_description)
      end
      dependency_hash = []
      SimpleHealthCheck::Configuration.all_checks.each_with_object(response) do |check, obj|
        begin
          if check.is_a?(SimpleHealthCheck::AsyncHttpEndpointCheck)
            # returns an array of HttpEndpointObj and responses
            async_responses = check.call(response: obj)
            async_responses.each do |response|
              status, error = response[:response]
              http_endpoint_obj = response[:http_endpoint_obj]
              dependency_hash << structure_dependency_response(http_endpoint_obj, status, error) unless http_endpoint_obj.service_name.nil?
            end
          else
            status, error = check.call(response: obj)
            dependency_hash << structure_dependency_response(check, status, error) unless check.service_name.nil? 
          end
        rescue # catch the error and try to log, but keep going finish all checks
          Rails.logger.error "simple_health_check gem ERROR: #{$ERROR_INFO}"
        end
      end
      response.add name: :dependencies, status: dependency_hash
      response.add name: 'status', status: response.overall_status
      response
    end

    private

    def structure_dependency_response(check, status, error)
      {
        name: check.service_name,
        type: check.type,
        version: check.version,
        responseTime: check.response_time,
        state: [
          status: status,
          error: error
        ]
      }
    end
  end
end
