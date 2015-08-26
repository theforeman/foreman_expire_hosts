module ExpireHostsNotifications
  class << self

    def admin_email
      return [(Setting[:host_expiry_email_recipients] || Setting.where("name = 'administrator'").first.try(:value))]
    end

    def days_to_delete_after_expired
      days_to_delete_after_expiry = Setting[:days_to_delete_after_host_expiration].to_i
      (days_to_delete_after_expiry == 0) ? 3 : days_to_delete_after_expiry.to_i
    end

    # This method to deliver deleted host details to its owner
    def delete_expired_hosts
      deletable_hosts     = Host.where("expired_on <= '#{(Date.today - ExpireHostsNotifications.days_to_delete_after_expired.to_i)}'")
      failed_delete_hosts = []
      deleted_hosts       = []
      deletable_hosts.each { |deletable_host|
        deletable_host.audit_comment = "Destroyed since it got expired on #{deletable_host.expired_on.strftime('%d %b %Y')}"
        if deletable_host.destroy
          deleted_hosts << deletable_host
        else
          failed_delete_hosts << deletable_host
        end
      }
      unless deleted_hosts.empty?
        ExpireHostsNotifications.hosts_by_user(deleted_hosts).each do |user_id, hosts_hash|
          begin
            ExpireHostsMailer.deleted_hosts_notification(hosts_hash['name'], hosts_hash['email'], hosts_hash['hosts']).deliver
          rescue Exception => e
            puts 'Failed to deliver deleted hosts notification'
            puts "Host ID(s): #{deleted_hosts.map { |h| h.id }.join(', ')}"
            puts e.message
            puts e.backtrace
          end
        end
      end
      unless failed_delete_hosts.empty?
        begin
          ExpireHostsMailer.failed_to_delete_hosts_notification('Admin', ExpireHostsNotifications.admin_email, failed_delete_hosts).deliver
        rescue Exception => e
          puts 'Failed to deliver deleted hosts notification failed status'
          puts "Host ID(s): #{failed_delete_hosts.map { |h| h.id }.join(', ')}"
          puts e.message
          puts e.backtrace
        end
      end
    end

    def stop_expired_hosts
      stoppable_hosts   = Host.where("expired_on <= '#{Date.today}'")
      failed_stop_hosts = []
      stopped_hosts     = []
      stoppable_hosts.each { |stoppable_host|
        host_status = begin
          stoppable_host.power.stop
        rescue Exception => e
          e.message.to_s.include?('not running')
        end
        if host_status
          stopped_hosts << stoppable_host
        else
          failed_stop_hosts << stoppable_host
        end
      }
      unless stopped_hosts.empty?
        delete_date = (Date.today + ExpireHostsNotifications.days_to_delete_after_expired.to_i)
        ExpireHostsNotifications.hosts_by_user(stopped_hosts).each do |user_id, hosts_hash|
          begin
            ExpireHostsMailer.stopped_hosts_notification(hosts_hash['name'], hosts_hash['email'], delete_date, hosts_hash['hosts']).deliver
          rescue Exception => e
            puts 'Failed to deliver stopped hosts notification'
            puts "Host ID(s): #{stopped_hosts.map { |h| h.id }.join(', ')}"
            puts e.message
            puts e.backtrace
          end
        end
      end
      unless failed_stop_hosts.empty?
        begin
          ExpireHostsMailer.failed_to_stop_hosts_notification('Admin', ExpireHostsNotifications.admin_email, failed_stop_hosts).deliver
        rescue Exception => e
          puts 'Failed to deliver stopped hosts notification failed status'
          puts "Host ID(s): #{failed_stop_hosts.map { |h| h.id }.join(', ')}"
          puts e.message
          puts e.backtrace
        end
      end
    end

    def deliver_expiry_warning_notification(num=1) #notify1_days_before_expiry
      return unless [1, 2].include?(num)
      default_days = (num == 1 ? 7 : 1)
      days_before_expiry = Setting["notify#{num}_days_before_host_expiry"].to_i
      days_before_expiry = (days_before_expiry == 0) ? default_days : days_before_expiry.to_i
      expiry_date        = (Date.today + days_before_expiry.to_i)
      notifiable_hosts   = Host.where("expired_on = '#{ expiry_date }'")
      unless notifiable_hosts.empty?
        ExpireHostsNotifications.hosts_by_user(notifiable_hosts).each do |user_id, hosts_hash|
          begin
            ExpireHostsMailer.expiry_warning_notification(hosts_hash['name'], hosts_hash['email'], expiry_date, hosts_hash['hosts']).deliver
          rescue Exception => e
            puts 'Failed to deliver expiring hosts notification'
            puts "Host ID(s): #{notifiable_hosts.map { |h| h.id }.join(', ')}"
            puts e.message
            puts e.backtrace
          end
        end
      end
    end

    def hosts_by_user(hosts)
      emails     = ExpireHostsNotifications.admin_email
      hosts_hash = {}
      hosts.each { |host|
        if host.owner_type == 'User'
          unless hosts_hash.has_key?("#{host.owner_id}")
            email_recipients = emails + [host.owner.mail]
            hosts_hash.merge!({ "#{host.owner_id}" => { 'id' => host.owner_id, 'name' => host.owner.name, 'email' => email_recipients, 'hosts' => [] } })
          end
          hosts_hash["#{host.owner_id}"]['hosts'] << host
        elsif host.owner_type == 'Usergroup'
          host.owner.users.each { |owner|
            unless hosts_hash.has_key?("#{owner.id}")
              email_recipients = emails + [owner.mail]
              hosts_hash.merge!({ "#{owner.id}" => { 'id' => owner.id, 'name' => owner.name, 'email' => email_recipients, 'hosts' => [] } })
            end
            hosts_hash["#{owner.id}"]['hosts'] << host
          }
        else
          email = ((!emails.empty?) ? emails : [Setting[:administrator]])
          unless hosts_hash.has_key?("#{owner.id}")
            hosts_hash.merge!({ 'admin' => { 'id' => nil, 'name' => 'Admin', 'email' => email, 'hosts' => [] } })
          end
          hosts_hash['admin']['hosts'] << host
        end
      }
      hosts_hash
    end
  end

end