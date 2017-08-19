module ForemanExpireHosts
  module Notification
    class StoppedHosts < Base
      attr_accessor :delete_date

      def initialize(opts)
        super
        @delete_date = opts.fetch(:delete_date)
      end

      private

      def humanized_name
        _('Stopped Hosts Notification')
      end

      def build_notification(recipient_mail, hosts)
        ExpireHostsMailer.stopped_hosts_notification(recipient_mail, delete_date, hosts)
      end
    end
  end
end
