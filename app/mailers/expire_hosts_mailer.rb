class ExpireHostsMailer < ApplicationMailer
  default :content_type => 'text/html', :from => Setting[:email_reply_address] || 'noreply@your-foreman.com'

  def deleted_hosts_notification(recipient, hosts)
    @hosts = hosts
    build_mail(recipient: recipient, subject: N_('Deleted expired hosts in Foreman'))
  end

  def failed_to_delete_hosts_notification(recipient, hosts)
    @hosts = hosts
    build_mail(recipient: recipient, subject: N_('Failed to delete expired hosts in Foreman'))
  end

  def stopped_hosts_notification(recipient, delete_date, hosts)
    @hosts       = hosts
    @delete_date = delete_date
    build_mail(recipient: recipient, subject: N_('Stopped expired hosts in Foreman'))
  end

  def failed_to_stop_hosts_notification(recipient, hosts)
    @hosts = hosts
    build_mail(recipient: recipient, subject: N_('Failed to stop expired hosts in Foreman'))
  end

  def expiry_warning_notification(recipient, expiry_date, hosts)
    @hosts       = hosts
    @expiry_date = expiry_date
    build_mail(recipient: recipient, subject: N_('Expiring hosts in foreman'))
  end

  private

  def build_mail(opts = {})
    recipient = opts[:recipient]
    subject = opts[:subject]
    set_locale_for(recipient) do
      mail(:to => recipient_mail(recipient), :subject => _(subject), :importance => 'High') do |format|
        format.html { render :layout => 'application_mailer' }
      end
    end
  end

  def recipient_mail(recipient)
    return recipient.mail if recipient.mail.present?
    admin_email
  end

  def admin_email
    (Setting[:host_expiry_email_recipients] || Setting[:administrator])
  end
end
