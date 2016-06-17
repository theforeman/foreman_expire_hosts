module ExpireHostsNotifications
  class << self

    def admin_email
      [(Setting[:host_expiry_email_recipients] || Setting[:administrator])]
    end

    def days_to_delete_after_expired
      Setting[:days_to_delete_after_host_expiration].to_i
    end

    def catch_delivery_errors(message, hosts = [])
      yield
    rescue => error
      message = "#{message} for Hosts #{hosts.map(&:name).to_sentence}"
      Foreman::Logging.exception(message, error)
    end

    # This method to deliver deleted host details to its owner
    def delete_expired_hosts
      deletable_hosts     = Host.expired_past_grace_period
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
        ExpireHostsNotifications.hosts_by_user(deleted_hosts).each do |user_id, hosts_hash|
          catch_delivery_errors(_('Failed to deliver deleted hosts notification'), deleted_hosts) do
            ExpireHostsMailer.deleted_hosts_notification(hosts_hash['email'], hosts_hash['hosts']).deliver
          end
        end
      end
      return if failed_delete_hosts.empty?
      catch_delivery_errors(_('Failed to deliver deleted hosts notification failed status'), failed_delete_hosts) do
        ExpireHostsMailer.failed_to_delete_hosts_notification(self.admin_email, failed_delete_hosts).deliver
      end
    end

    def stop_expired_hosts
      stoppable_hosts   = Host.expired
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
        hosts_by_user(stopped_hosts).each do |user_id, hosts_hash|
          catch_delivery_errors(_('Failed to deliver stopped hosts notification'), stopped_hosts) do
            ExpireHostsMailer.stopped_hosts_notification(hosts_hash['email'], delete_date, hosts_hash['hosts']).deliver
          end
        end
      end
      return if failed_stop_hosts.empty?
      catch_delivery_errors(_('Failed to deliver stopped hosts notification failed status'), failed_stop_hosts) do
        ExpireHostsMailer.failed_to_stop_hosts_notification(self.admin_email, failed_stop_hosts).deliver
      end
    end

    def deliver_expiry_warning_notification(num = 1) # notify1_days_before_expiry
      return unless [1, 2].include?(num)
      days_before_expiry = Setting["notify#{num}_days_before_host_expiry"].to_i
      expiry_date        = (Date.today + days_before_expiry)
      notifiable_hosts   = Host.with_expire_date(expiry_date)
      unless notifiable_hosts.empty?
        hosts_by_user(notifiable_hosts).each do |user_id, hosts_hash|
          catch_delivery_errors(_('Failed to deliver expiring hosts notification'), notifiable_hosts) do
            ExpireHostsMailer.expiry_warning_notification(hosts_hash['email'], expiry_date, hosts_hash['hosts']).deliver
          end
        end
      end
    end

    def hosts_by_user(hosts)
      emails     = self.admin_email
      hosts_hash = {}
      hosts.each do |host|
        if host.owner_type == 'User'
          unless hosts_hash.key?(host.owner_id.to_s)
            email_recipients = emails + [host.owner.mail]
            hosts_hash[host.owner_id.to_s] = { 'id' => host.owner_id, 'name' => host.owner.name, 'email' => email_recipients, 'hosts' => [] }
          end
          hosts_hash[host.owner_id.to_s]['hosts'] << host
        elsif host.owner_type == 'Usergroup'
          host.owner.users.each do |owner|
            unless hosts_hash.key?(owner.id.to_s)
              email_recipients = emails + [owner.mail]
              hosts_hash[owner.id.to_s] = { 'id' => owner.id, 'name' => owner.name, 'email' => email_recipients, 'hosts' => [] }
            end
            hosts_hash[owner.id.to_s]['hosts'] << host
          end
        else
          email = (!emails.empty? ? emails : [Setting[:administrator]])
          unless hosts_hash.key?(owner.id.to_s)
            hosts_hash['admin'] = { 'id' => nil, 'name' => 'Admin', 'email' => email, 'hosts' => [] }
          end
          hosts_hash['admin']['hosts'] << host
        end
      end
      hosts_hash
    end
  end
end
