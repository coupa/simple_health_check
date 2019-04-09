class SimpleHealthCheck::MysqlCheck < SimpleHealthCheck::Base
  def initialize service_name: "mysql", check_proc: nil, hard_fail: false
    @service_name = service_name.to_s
    @proc = check_proc || SimpleHealthCheck::Configuration.mysql_check_proc
    @hard_fail = hard_fail
    @response_time = nil
    @type = 'internal'
    @version = version_check || nil
  end

  def call(response:)
    status = nil
    error = ''
    begin
      # @proc is a user-supplied function to see if mysql connection is working.
      # It can be as simple as `User.first`
      # If it doesn't throw an exception, we're good
      start_time = Time.now
      if @proc && @proc.respond_to?(:call)
        connection = @proc.call
      else
        # try using standard connection methods to see if it is connected
        connection = ActiveRecord::Base.connected?
      end
      @response_time = Time.now - start_time
      @version = @version.nil? ? version_check : @version
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

  def version_check
    ActiveRecord::Base.connection.select_rows('SELECT VERSION()')[0][0]
  end
end
