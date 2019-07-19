# frozen_string_literal: true

module ForemanExpireHosts
  module Notification
    class FailedStoppedHosts < Base
      private

      def humanized_name
        _('Failed Stopped Hosts Notification')
      end

      def build_mail_notification(recipient, hosts)
        ExpireHostsMailer.failed_to_stop_hosts_notification(recipient, hosts)
      end
    end
  end
end
