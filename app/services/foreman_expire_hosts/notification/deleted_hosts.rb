module ForemanExpireHosts
  module Notification
    class DeletedHosts < Base
      private

      def humanized_name
        _('Deleted Hosts Notification')
      end

      def build_mail_notification(recipient, hosts)
        ExpireHostsMailer.deleted_hosts_notification(recipient, hosts)
      end
    end
  end
end
