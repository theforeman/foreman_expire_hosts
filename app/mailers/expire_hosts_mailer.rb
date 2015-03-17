class ExpireHostsMailer < ActionMailer::Base

	default :content_type => "text/html", :from => Setting[:email_reply_address] || "noreply@your-foreman.com"

	def deleted_hosts_notification(user_name, emails, hosts)
		@user_name = user_name
		@hosts = hosts
		mail(:to => emails, :subject => "Deleted expired hosts in Foreman", :importance => "High" )
	end

	def failed_to_delete_hosts_notification(user_name, emails, hosts)
		@user_name = user_name
		@hosts = hosts
		@url = URI.parse(Setting[:foreman_url])
		mail(:to => emails, :subject => "Failed to delete expired hosts in Foreman", :importance => "High")
	end

	def stopped_hosts_notification(user_name, emails, delete_date, hosts)
		@user_name = user_name
		@hosts = hosts
		@delete_date = delete_date
		@url = URI.parse(Setting[:foreman_url])
		mail(:to => emails, :subject => "Stopped expired hosts in Foreman", :importance => "High")
	end

	def failed_to_stop_hosts_notification(user_name, emails, hosts)
		@user_name = user_name
		@hosts = hosts
		@url = URI.parse(Setting[:foreman_url])
		mail(:to => emails, :subject => "Failed to stop expired hosts in Foreman", :importance => "High")
	end

	def expiry_warning_notification(user_name, emails, expiry_date, hosts)
		@user_name = user_name
		@hosts = hosts
		@expiry_date = expiry_date
		@url = URI.parse(Setting[:foreman_url])
		mail(:to => emails, :subject => "Expiring hosts in foreman", :importance => "High")
	end
end