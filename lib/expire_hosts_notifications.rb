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
      ForemanExpireHosts::Notification::DeletedHosts.new(
        :hosts => deleted_hosts
      ).deliver
      ForemanExpireHosts::Notification::FailedDeletedHosts.new(
        :hosts => failed_delete_hosts,
        :to => User.anonymous_admin
      ).deliver
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
      delete_date = (Date.today + self.days_to_delete_after_expired.to_i)
      ForemanExpireHosts::Notification::StoppedHosts.new(
        :hosts => stopped_hosts,
        :delete_date => delete_date
      ).deliver
      ForemanExpireHosts::Notification::FailedStoppedHosts.new(
        :hosts => failed_stop_hosts,
        :to => User.anonymous_admin
      ).deliver
    end

    def deliver_expiry_warning_notification(num = 1) # notify1_days_before_expiry
      return unless [1, 2].include?(num)
      days_before_expiry = Setting["notify#{num}_days_before_host_expiry"].to_i
      expiry_date        = (Date.today + days_before_expiry)
      notifiable_hosts   = Host.with_expire_date(expiry_date).preload(:owner)

      ForemanExpireHosts::Notification::ExpiryWarning.new(
        :hosts => notifiable_hosts,
        :expiry_date => expiry_date
      ).deliver
    end

    def days_to_delete_after_expired
      Setting[:days_to_delete_after_host_expiration].to_i
    end
  end
end
