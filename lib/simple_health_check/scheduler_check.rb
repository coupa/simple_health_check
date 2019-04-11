class SimpleHealthCheck::SchedulerCheck < SimpleHealthCheck::BaseNoProc
  def initialize service_name: "scheduler", check_proc: nil
    @service_name = service_name
    @proc = check_proc || SimpleHealthCheck::Configuration.scheduler_check_proc
    @type = 'internal'
  end

  def call(response:)
    super { (Resque.workers.empty? == false) }
  end

end
