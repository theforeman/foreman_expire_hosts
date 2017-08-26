module ForemanExpireHosts
  module Action
    class DeleteExpiredHosts < Base
      private

      def selector
        Host.expired_past_grace_period
      end

      def action(host)
        host.destroy
      end

      def success_notification
        ForemanExpireHosts::Notification::DeletedHosts
      end

      def failure_notification
        ForemanExpireHosts::Notification::FailedDeletedHosts
      end
    end
  end
end
