module SimpleHealthCheck
  class Base
    attr_reader :service_name
    attr_reader :response_time
    attr_reader :type
    attr_reader :version
    # derive a check class from this and add your checks.  the passed in response object
    # can set the key (name) and value (status) of the check to run.
    # All the combined checks are returned in a single hash.  Ensure you catch
    # any exceptions and set the reponse appropriately.
    # Make use of your derived check class by adding it to the list of check in your
    # app initializer:
    #
    # config/initializers/health_check.rb
    # ```
    # SimpleHealthCheck::Configuration.configure do |config|
    #   config.add_check SimpleHealthCheck::VersionCheck
    # end
    # ```
    # or, if you need to initialize the instance with data:
    # ```
    # SimpleHealthCheck::Configuration.configure do |config|
    #   config.add_check MyCheck.new(data)
    # end
    # ```
    def initialize service_name: nil, check_proc: nil, hard_fail: false
      @service_name = service_name
      @proc = check_proc
      @hard_fail = hard_fail
      @response_time = nil
    end

    def should_hard_fail?
      @hard_fail
    end

    def call(response:)
      status = nil
      error = ''
      if @proc && @proc.respond_to?(:call)
        begin
          # @proc is a required user-supplied function to see if connection is working.
          start_time = Time.now
          connection = @proc.call
          @response_time = Time.now - start_time
          status = connection ? :ok : :crit
          response.status_code = status
        rescue
          # catch exceptions since we don't want the health-check to bubble all the way to the top
          status = :crit
          error = $ERROR_INFO.to_s
          response.status_code = :crit
        end
      else
        response.status_code = :crit unless @no_config_needed
      end
      [status, error]
    end
  end
end
