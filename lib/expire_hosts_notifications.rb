# frozen_string_literal: true

module ExpireHostsNotifications
  class << self
    def delete_expired_hosts
      ForemanExpireHosts::Action::DeleteExpiredHosts.new.engage
    end

    def stop_expired_hosts
      ForemanExpireHosts::Action::StopExpiredHosts.new.engage
    end

    def deliver_expiry_warning_notification(num = 1) # notify1_days_before_expiry
      return unless [1, 2].include?(num)

      days_before_expiry = Setting["notify#{num}_days_before_host_expiry"].to_i
      expiry_date        = (Date.today + days_before_expiry)
      notifiable_hosts   = Host.with_expire_date(expiry_date).preload(:owner)

      ForemanExpireHosts::Notification::ExpiryWarning.new(
        hosts: notifiable_hosts,
        expiry_date: expiry_date
      ).deliver
    end
  end
end
