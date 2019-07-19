# frozen_string_literal: true

module ForemanExpireHosts
  module Notification
    class FailedDeletedHosts < Base
      private

      def humanized_name
        _('Failed Deleted Hosts Notification')
      end

      def build_mail_notification(recipient, hosts)
        ExpireHostsMailer.failed_to_delete_hosts_notification(recipient, hosts)
      end
    end
  end
end
