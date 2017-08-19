module ForemanExpireHosts
  module Notification
    class DeletedHosts < Base
      private

      def humanized_name
        _('Deleted Hosts Notification')
      end

      def build_notification(recipient_mail, hosts)
        ExpireHostsMailer.deleted_hosts_notification(recipient_mail, hosts)
      end
    end
  end
end
