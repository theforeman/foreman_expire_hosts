# frozen_string_literal: true

module ForemanExpireHosts
  module Notification
    class Base
      attr_accessor :all_hosts, :global_recipients

      def initialize(opts)
        @all_hosts = opts.fetch(:hosts)
        @global_recipients = [opts[:to]].flatten.compact
      end

      def deliver
        deliver_mail_notifications if respond_to?(:build_mail_notification, true)
        deliver_ui_notifications if respond_to?(:build_ui_notification, true)
      end

      private

      def deliver_mail_notifications
        hosts_by_recipient(all_hosts).each do |recipient, hosts|
          deliver_mail_notification(recipient, hosts)
        end
        deliver_mail_notification(additional_recipients, all_hosts) if additional_recipients.present?
        true
      end

      def deliver_mail_notification(recipient, hosts)
        return true if hosts.empty?

        build_mail_notification(recipient, hosts).deliver_now
      rescue SocketError, Net::SMTPError => e
        message = _('Failed to deliver %{notification_name} for Hosts %{hosts}') % {
          :notification_name => humanized_name,
          :hosts => hosts.map(&:name).to_sentence
        }
        Foreman::Logging.exception(message, e)
      end

      def deliver_ui_notifications
        all_hosts.each do |host|
          build_ui_notification(host).deliver!
        end
      end

      delegate :logger, :to => :Rails

      def humanized_name
        _('Notification')
      end

      def hosts_by_recipient(hosts)
        hosts.each_with_object({}) do |host, hash|
          recipients = recipients_for_host(host)
          recipients.each do |recipient|
            hash[recipient] ||= []
            hash[recipient] << host
          end
        end
      end

      def recipients_for_host(host)
        return global_recipients if global_recipients.present?
        return [User.anonymous_admin] if host.owner.blank?
        return [host.owner] if host.owner_type == 'User'

        host.owner.all_users
      end

      def additional_recipients
        return [] if Setting[:host_expiry_email_recipients].nil?

        Setting[:host_expiry_email_recipients].split(',').compact.map(&:strip)
      end
    end
  end
end
