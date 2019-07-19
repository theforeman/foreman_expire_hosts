# frozen_string_literal: true

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

      def build_ui_notification(host)
        ForemanExpireHosts::UINotifications::Hosts::ExpiryWarning.new(host)
      end

      def build_mail_notification(recipient, hosts)
        ExpireHostsMailer.expiry_warning_notification(recipient, expiry_date, hosts)
      end
    end
  end
end
