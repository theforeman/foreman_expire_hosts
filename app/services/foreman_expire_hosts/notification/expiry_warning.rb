module ForemanExpireHosts
  module Notification
    class ExpiryWarning < Base
      attr_accessor :expiry_date

      def initialize(opts)
        super
        @expiry_date = opts.fetch(:expiry_date)
      end

      private

      def humanized_name
        _('Host Expiry Warning Notification')
      end

      def build_notification(recipient_mail, hosts)
        ExpireHostsMailer.expiry_warning_notification(recipient_mail, expiry_date, hosts)
      end
    end
  end
end
