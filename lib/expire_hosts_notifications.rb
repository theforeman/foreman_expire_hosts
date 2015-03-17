module ExpireHostsNotificaions
	class << self

		def admin_email
			notify_emails  = SETTINGS[:host_expired_on].try(:fetch, :delete_hosts).try(:fetch, :notify_emails) rescue []
			emails = ((notify_emails.kind_of?(Array) and !notify_emails.empty?) ? notify_emails : ((notify_emails.kind_of?(String) and !notify_emails.blank?) ? [notify_emails] : []))
			return ((!emails.empty?) ? emails : [Setting.where("name = 'administrator'").first.try(:value)])
		end

		def days_to_delete_after_expired
			days_to_delete_after_expired  = SETTINGS[:host_expired_on].try(:fetch, :delete_hosts).try(:fetch, :days_to_delete_after_expiration).to_s rescue ""
			days_to_delete_after_expired = days_to_delete_after_expired.match(/^[0-9]+$/).nil? ? 3 : days_to_delete_after_expired.to_i
			return days_to_delete_after_expired
		end

		def from_day_to_notify_before_expiry
			days_before_expiry  = SETTINGS[:host_expired_on].try(:fetch, :delete_hosts).try(:fetch, :notify1_days_before_expiry).to_s rescue ""
			days_before_expiry = days_before_expiry.match(/^[0-9]+$/).nil? ? 7 : days_before_expiry.to_i
			return (Date.today + days_before_expiry.to_i)
		end

		# This method to deliver deleted host details to its owner
		def delete_expired_hosts			
			deletable_hosts = Host.where("expired_on <= '#{(Date.today - ExpireHostsNotificaions.days_to_delete_after_expired.to_i)}'")
			failed_delete_hosts = []
			deleted_hosts = []
			for deletable_host in deletable_hosts
				deletable_host.audit_comment = "Destroyed since it got expired on #{deletable_host.expired_on.strftime("%d %b %Y")}"
				if deletable_host.destroy
					deleted_hosts << deletable_host
				else
					failed_delete_hosts << deletable_host
				end
			end
			unless deleted_hosts.empty?
				ExpireHostsNotificaions.hosts_by_user(deleted_hosts).each do |user_id, hosts_hash|
					begin
						ExpireHostsMailer.deleted_hosts_notification(hosts_hash["name"], hosts_hash["email"], hosts_hash["hosts"]).deliver
					rescue Exception => e
						puts "Failed to deliver deleted hosts notification"
						puts "Host ID(s): #{deleted_hosts.map{|h| h.id}.join(', ')}"
						puts e.message
						puts e.backtrace
					end
				end
			end
			unless failed_delete_hosts.empty?				
				begin
					ExpireHostsMailer.failed_to_delete_hosts_notification("Admin", ExpireHostsNotificaions.admin_email, failed_delete_hosts).deliver
				rescue Exception => e
					puts "Failed to deliver deleted hosts notification failed status"
					puts "Host ID(s): #{failed_delete_hosts.map{|h| h.id}.join(', ')}"
					puts e.message
					puts e.backtrace
				end				
			end
		end

		def stop_expired_hosts
			stoppable_hosts = Host.where("expired_on <= '#{Date.today}'")
			failed_stop_hosts = []
			stopped_hosts = []
			for stoppable_host in stoppable_hosts
				host_status = begin
					stoppable_host.power.stop
				rescue Exception => e
					e.message.to_s.include?("not running")
				end
				if host_status
					stopped_hosts << stoppable_host
				else
					failed_stop_hosts << stoppable_host
				end
			end
			unless stopped_hosts.empty?
				delete_date = (Date.today + ExpireHostsNotificaions.days_to_delete_after_expired.to_i)
				ExpireHostsNotificaions.hosts_by_user(stopped_hosts).each do |user_id, hosts_hash|
					begin
						ExpireHostsMailer.stopped_hosts_notification(hosts_hash["name"], hosts_hash["email"], delete_date, hosts_hash["hosts"]).deliver
					rescue Exception => e
						puts "Failed to deliver stopped hosts notification"
						puts "Host ID(s): #{stopped_hosts.map{|h| h.id}.join(', ')}"
						puts e.message
						puts e.backtrace
					end
				end
			end
			unless failed_stop_hosts.empty?				
				begin
					ExpireHostsMailer.failed_to_stop_hosts_notification("Admin", ExpireHostsNotificaions.admin_email, failed_stop_hosts).deliver
				rescue Exception => e
					puts "Failed to deliver stopped hosts notification failed status"
					puts "Host ID(s): #{failed_stop_hosts.map{|h| h.id}.join(', ')}"
					puts e.message
					puts e.backtrace
				end				
			end
		end

		def deliver_expiry_warning_notification(num=1) #notify1_days_before_expiry
			return unless [1, 2].include?(num)
			default_days = (num == 1 ? 7 : 1)
			days_before_expiry  = SETTINGS[:host_expired_on].try(:fetch, :delete_hosts).try(:fetch, "notify#{num}_days_before_expiry".to_sym).to_s rescue ""
			days_before_expiry = days_before_expiry.match(/^[0-9]+$/).nil? ? default_days : days_before_expiry.to_i
			expiry_date = (Date.today + days_before_expiry.to_i)
			notifiable_hosts = Host.where("expired_on = '#{ expiry_date }'")
			unless notifiable_hosts.empty?
				ExpireHostsNotificaions.hosts_by_user(notifiable_hosts).each do |user_id, hosts_hash|
					begin
						ExpireHostsMailer.expiry_warning_notification(hosts_hash["name"], hosts_hash["email"], expiry_date, hosts_hash["hosts"]).deliver
					rescue Exception => e
						puts "Failed to deliver expiring hosts notification"
						puts "Host ID(s): #{notifiable_hosts.map{|h| h.id}.join(', ')}"
						puts e.message
						puts e.backtrace
					end
				end
			end
		end

		def hosts_by_user(hosts)
			notify_emails  = SETTINGS[:host_expired_on].try(:fetch, :delete_hosts).try(:fetch, :notify_emails) rescue []
			emails = ((notify_emails.kind_of?(Array) and !notify_emails.empty?) ? notify_emails : ((notify_emails.kind_of?(String) and !notify_emails.blank?) ? [notify_emails] : []))
			hosts_hash = {}
			for host in hosts
				if host.owner_type == "User"
					unless hosts_hash.has_key?("#{host.owner_id}")
						email_recipients = emails + [host.owner.mail]
						hosts_hash.merge!({"#{host.owner_id}" => {"id" => host.owner_id, "name" => host.owner.name, "email" => email_recipients, "hosts" => []}})
					end
					hosts_hash["#{host.owner_id}"]["hosts"] << host
				elsif host.owner_type == "Usergroup"
					for owner in host.owner.users
						unless hosts_hash.has_key?("#{owner.id}")
							email_recipients = emails + [owner.mail]
							hosts_hash.merge!({"#{owner.id}" => {"id" => owner.id, "name" => owner.name, "email" => email_recipients, "hosts" => []}})
						end
						hosts_hash["#{owner.id}"]["hosts"] << host
					end
				else					
					email = ((!emails.empty?) ? emails : [Setting[:administrator]])
					unless hosts_hash.has_key?("#{owner.id}")
						hosts_hash.merge!({"admin" => {"id" => nil, "name" => "Admin", "email" => email, "hosts" => []}})
					end
					hosts_hash["admin"]["hosts"] << host
				end
			end
			return hosts_hash
		end
	end

end