# frozen_string_literal: true

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

      def build_ui_notification(host)
        ForemanExpireHosts::UINotifications::Hosts::StoppedHost.new(host)
      end

      def build_mail_notification(recipient, hosts)
        ExpireHostsMailer.stopped_hosts_notification(recipient, delete_date, hosts)
      end
    end
  end
end
