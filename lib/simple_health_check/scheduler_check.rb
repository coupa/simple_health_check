# Pass in time_frame as Time object i.e. 30.minutes or 1.hour
class SimpleHealthCheck::SchedulerCheck < SimpleHealthCheck::BaseNoProc
  def initialize service_name: 'scheduler', check_proc: nil, last_ran_job: nil, time_frame: nil
    @service_name = service_name
    @proc = check_proc || SimpleHealthCheck::Configuration.scheduler_check_proc
    @type = 'internal'
    @last_ran_job = last_ran_job
    @time_frame = time_frame
  end

  def call(response:)
    super do
      unless @time_frame.nil? | @last_ran_job.nil?
        (Time.now - @last_ran_job) <= @time_frame.to_i
      end
    end
  end
end
