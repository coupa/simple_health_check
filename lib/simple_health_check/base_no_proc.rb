class SimpleHealthCheck::BaseNoProc < SimpleHealthCheck::Base
  def initialize service_name: nil, check_proc: nil
    super
  end

  # proc-not required call
  def call(response:)
    status = nil
    error = ''
    begin
      # @proc is a user-supplied function to see if connection is working.
      start_time = Time.now
      if @proc && @proc.respond_to?(:call)
        connection = @proc.call
      else
        # try using standard connection methods to see if it is connected
        connection = yield
      end
      @response_time = Time.now - start_time
      status = connection ? :ok : :crit
      response.status_code = status
    rescue
      # catch exceptions since we don't want the health-check to bubble all the way to the top
      status = :crit
      error = $ERROR_INFO.to_s
      response.status_code = :crit
    end
    [status, error]
  end
end
