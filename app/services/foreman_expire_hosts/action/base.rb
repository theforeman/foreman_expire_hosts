# frozen_string_literal: true

module ForemanExpireHosts
  module Action
    class Base
      attr_accessor :successful_hosts, :failed_hosts

      def initialize
        self.successful_hosts = []
        self.failed_hosts = []
      end

      def engage
        process
        notify
      end

      private

      def process
        hosts.each do |host|
          result = action(host)
          next if result.nil?

          if result
            logger.info "Action #{self.class.name} for host #{host.name} was successful."
            successful_hosts << host
          else
            logger.info "Action #{self.class.name} for host #{host.name} failed."
            failed_hosts << host
          end
        end
      end

      def notify
        success_notification.new(
          success_notification_options
        ).deliver
        failure_notification.new(
          failure_notification_options
        ).deliver
      end

      def hosts
        selector.preload(:owner)
      end

      def success_notification_options
        {
          hosts: successful_hosts
        }
      end

      def failure_notification_options
        {
          hosts: failed_hosts,
          to: User.anonymous_admin
        }
      end

      delegate :logger, to: :ForemanExpireHosts
    end
  end
end
