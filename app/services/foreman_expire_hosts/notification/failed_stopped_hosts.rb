module ForemanExpireHosts
  module Notification
    class FailedStoppedHosts < Base
      private

      def humanized_name
        _('Failed Stopped Hosts Notification')
      end

      def build_notification(recipient_mail, hosts)
        ExpireHostsMailer.failed_to_stop_hosts_notification(recipient_mail, hosts)
      end
    end
  end
end
