module ExpireHostsNotifications
  class << self
    def delete_expired_hosts
      deletable_hosts     = Host.expired_past_grace_period.preload(:owner)
      failed_delete_hosts = []
      deleted_hosts       = []
      deletable_hosts.each do |deletable_host|
        Rails.logger.info "Deleting expired host #{deletable_host}"
        deletable_host.audit_comment = _('Destroyed since it got expired on %s') % deletable_host.expired_on
        if deletable_host.destroy
          deleted_hosts << deletable_host
        else
          failed_delete_hosts << deletable_host
        end
      end
      unless deleted_hosts.empty?
        hosts_by_recipient(deleted_hosts).each do |recipient, hosts|
          catch_delivery_errors(_('Failed to deliver deleted hosts notification'), deleted_hosts) do
            ExpireHostsMailer.deleted_hosts_notification(recipient, hosts).deliver_now
          end
        end
      end
      return if failed_delete_hosts.empty?
      catch_delivery_errors(_('Failed to deliver deleted hosts notification failed status'), failed_delete_hosts) do
        ExpireHostsMailer.failed_to_delete_hosts_notification(self.admin_email, failed_delete_hosts).deliver_now
      end
    end

    def stop_expired_hosts
      stoppable_hosts   = Host.expired.preload(:owner)
      failed_stop_hosts = []
      stopped_hosts     = []
      stoppable_hosts.each do |stoppable_host|
        next unless stoppable_host.supports_power_and_running?
        Rails.logger.info "Powering down expired host in grace period #{stoppable_host}"
        host_status = begin
          stoppable_host.power.stop
        rescue
          false
        end
        if host_status
          stopped_hosts << stoppable_host
        else
          failed_stop_hosts << stoppable_host
        end
      end
      unless stopped_hosts.empty?
        delete_date = (Date.today + self.days_to_delete_after_expired.to_i)
        hosts_by_recipient(stopped_hosts).each do |recipient, hosts|
          catch_delivery_errors(_('Failed to deliver stopped hosts notification'), stopped_hosts) do
            ExpireHostsMailer.stopped_hosts_notification(recipient, delete_date, hosts).deliver_now
          end
        end
      end
      return if failed_stop_hosts.empty?
      catch_delivery_errors(_('Failed to deliver stopped hosts notification failed status'), failed_stop_hosts) do
        ExpireHostsMailer.failed_to_stop_hosts_notification(self.admin_email, failed_stop_hosts).deliver_now
      end
    end

    def deliver_expiry_warning_notification(num = 1) # notify1_days_before_expiry
      return unless [1, 2].include?(num)
      days_before_expiry = Setting["notify#{num}_days_before_host_expiry"].to_i
      expiry_date        = (Date.today + days_before_expiry)
      notifiable_hosts   = Host.with_expire_date(expiry_date).preload(:owner)
      return if notifiable_hosts.empty?

      hosts_by_recipient(notifiable_hosts).each do |recipient, hosts|
        catch_delivery_errors(_('Failed to deliver expiring hosts notification'), notifiable_hosts) do
          ExpireHostsMailer.expiry_warning_notification(recipient, expiry_date, hosts).deliver_now
        end
      end
    end

    def hosts_by_recipient(hosts)
      hosts.each_with_object({}) do |host, hash|
        recipients = host.owner.try(:recipients) || []
        recipients = self.admin_email unless recipients.present?
        recipients.each do |recipient|
          hash[recipient] ||= []
          hash[recipient] << host
        end
      end
    end

    def admin_email
      [(Setting[:host_expiry_email_recipients] || Setting[:administrator])]
    end

    def days_to_delete_after_expired
      Setting[:days_to_delete_after_host_expiration].to_i
    end

    def catch_delivery_errors(message, hosts = [])
      yield
    rescue SocketError, Net::SMTPError => error
      message = _('%{message} for Hosts %{hosts}') % { :message => message, :hosts => hosts.map(&:name).to_sentence }
      Foreman::Logging.exception(message, error)
    end
  end
end
