# frozen_string_literal: true

module ForemanExpireHosts
  module Action
    class StopExpiredHosts < Base
      private

      def selector
        Host.expired
      end

      def action(host)
        return false unless host.supports_power?
        return unless host.power.ready?

        logger.info "Powering down expired host in grace period #{host}."
        host.power.stop
      rescue StandardError
        false
      end

      def success_notification
        ForemanExpireHosts::Notification::StoppedHosts
      end

      def failure_notification
        ForemanExpireHosts::Notification::FailedStoppedHosts
      end

      def success_notification_options
        super.merge(
          delete_date: (Date.today + days_to_delete_after_expired)
        )
      end

      def days_to_delete_after_expired
        Setting[:days_to_delete_after_host_expiration].to_i
      end
    end
  end
end
