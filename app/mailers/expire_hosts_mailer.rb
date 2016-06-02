class ExpireHostsMailer < ApplicationMailer

  default :content_type => 'text/html', :from => Setting[:email_reply_address] || 'noreply@your-foreman.com'

  def deleted_hosts_notification(emails, hosts)
    @hosts = hosts
    mail(:to => emails, :subject => 'Deleted expired hosts in Foreman', :importance => 'High')
  end

  def failed_to_delete_hosts_notification(emails, hosts)
    @hosts = hosts
    mail(:to => emails, :subject => 'Failed to delete expired hosts in Foreman', :importance => 'High')
  end

  def stopped_hosts_notification(emails, delete_date, hosts)
    @hosts       = hosts
    @delete_date = delete_date
    mail(:to => emails, :subject => 'Stopped expired hosts in Foreman', :importance => 'High') do |format|
      format.html { render :layout => 'application_mailer' }
    end
  end

  def failed_to_stop_hosts_notification(emails, hosts)
    @hosts = hosts
    mail(:to => emails, :subject => 'Failed to stop expired hosts in Foreman', :importance => 'High') do |format|
      format.html { render :layout => 'application_mailer' }
    end
  end

  def expiry_warning_notification(emails, expiry_date, hosts)
    @hosts       = hosts
    @expiry_date = expiry_date
    mail(:to => emails, :subject => 'Expiring hosts in foreman', :importance => 'High') do |format|
      format.html { render :layout => 'application_mailer' }
    end
  end
end
