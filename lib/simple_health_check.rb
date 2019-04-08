require 'simple_health_check/base'
require 'simple_health_check/basic_status_check'

module SimpleHealthCheck
  %w[ generic_check http_endpoint_check json_file mysql_check redis_check s3_check version_check version].each do |file|
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

    def status_code
      @status || :ok
    end

    def status_code= val
      @status = val if @status != :ok
    end

    alias_method :status=, :status_code=
    alias_method :status, :status_code

    def body
      @body
    end
  end

  class << self
    def run_simple_checks
      response = SimpleHealthCheck::Response.new
      SimpleHealthCheck::Configuration.all_checks.each_with_object(response) do |check, obj|
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
      response.add name: :dependencies, status: []
      SimpleHealthCheck::Configuration.all_checks.each_with_object(response) do |check, obj|
        dependency_hash = {}
        begin
          status, error = check.call(response: obj)
          unless check.service_name.nil?
            dependency_hash[:name] = check.service_name
            dependency_hash[:type] = check.type
            dependency_hash[:version] = check.version
            dependency_hash[:responseTime] = check.response_time
            dependency_hash[:state] = [status: status, error: error]
            response.add name: :dependencies, status: dependency_hash
          end
        rescue # catch the error and try to log, but keep going finish all checks
          Rails.logger.error "simple_health_check gem ERROR: #{$ERROR_INFO}"
        end
      end
      response.add name: 'status', status: response.status_code
      response
    end
  end
end
