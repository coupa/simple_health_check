module SimpleHealthCheck
  module Configuration
    class << self
      # options for predefined checks:
      %w[
        generic_check
        simple_generic_check
        http_endpoint_check_proc
        json_file
        mount_at
        mysql_check_proc
        s3_check_proc
        resque_check_proc
        scheduler_check_proc
        version_file
        detailed_description
      ].each do |opt|
        attr_accessor opt.to_sym
      end

      attr_accessor :options

      SIMPLE_CHECK_TYPES = [
        SimpleHealthCheck::JsonFile,
        SimpleHealthCheck::VersionCheck,
        SimpleHealthCheck::SimpleGenericCheck
      ].freeze

      def simple_checks
        added_checks = all_checks.map { |x| x if SIMPLE_CHECK_TYPES.include?(x.class) }
        @simple_checks ||= added_checks.compact | [SimpleHealthCheck::BasicStatus.new]
      end

      def all_checks
        @checks ||= []
        @all_checks ||= @checks.map do |c|
          c.is_a?(Class) ? c.new : c
        end
        @all_checks ||= @checks.compact
      end

      def add_check klass_or_instance
        if klass_or_instance.respond_to?(:new)
          self.all_checks << klass_or_instance.new
        else
          self.all_checks << klass_or_instance
        end
      end

      def configure
        yield self if block_given?
        self
      end
    end

    self.mount_at = 'health'
    self.version_file = 'VERSION'
    self.detailed_description = nil
    self.options = {}
  end
end
