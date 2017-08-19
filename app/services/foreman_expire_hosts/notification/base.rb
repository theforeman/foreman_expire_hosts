module ForemanExpireHosts
  module Notification
    class Base
      attr_accessor :all_hosts, :global_recipients

      def initialize(opts)
        @all_hosts = opts.fetch(:hosts)
        @global_recipients = [opts[:to]].flatten.compact
      end

      def deliver
        hosts_by_recipient(all_hosts).each do |recipient, hosts|
          begin
            build_notification(recipient_mail(recipient), hosts).deliver_now
          rescue SocketError, Net::SMTPError => error
            message = _('Failed to deliver %{notification_name} for Hosts %{hosts}') % {
              :notification_name => humanized_name,
              :hosts => hosts.map(&:name).to_sentence
            }
            Foreman::Logging.exception(message, error)
          end
        end
        true
      end

      private

      delegate :logger, :to => :Rails

      def humanized_name
        _('Notification')
      end

      def recipient_mail(recipient)
        return recipient.mail if recipient.mail.present?
        admin_email
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

      def admin_email
        (Setting[:host_expiry_email_recipients] || Setting[:administrator])
      end
    end
  end
end
