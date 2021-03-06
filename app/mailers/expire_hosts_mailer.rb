# frozen_string_literal: true

class ExpireHostsMailer < ApplicationMailer
  default :content_type => 'text/html', :from => Setting[:email_reply_address] || 'noreply@your-foreman.com'

  def deleted_hosts_notification(recipient, hosts)
    build_mail(
      recipient: recipient,
      subject: N_('Deleted expired hosts in Foreman'),
      hosts: hosts
    )
  end

  def failed_to_delete_hosts_notification(recipient, hosts)
    build_mail(
      recipient: recipient,
      subject: N_('Failed to delete expired hosts in Foreman'),
      hosts: hosts
    )
  end

  def stopped_hosts_notification(recipient, delete_date, hosts)
    @delete_date = delete_date
    build_mail(
      recipient: recipient,
      subject: N_('Stopped expired hosts in Foreman'),
      hosts: hosts
    )
  end

  def failed_to_stop_hosts_notification(recipient, hosts)
    build_mail(
      recipient: recipient,
      subject: N_('Failed to stop expired hosts in Foreman'),
      hosts: hosts
    )
  end

  def expiry_warning_notification(recipient, expiry_date, hosts)
    @expiry_date = expiry_date
    build_mail(
      recipient: recipient,
      subject: N_('Expiring hosts in foreman'),
      hosts: hosts
    )
  end

  private

  def build_mail(opts = {})
    recipient = opts[:recipient]
    subject = opts[:subject]
    hosts = opts[:hosts]
    user = user_for_recipient(recipient)
    @hosts = hosts
    @authorized_for_expiry_date_change = ForemanExpireHosts::ExpiryEditAuthorizer.new(
      :user => user,
      :hosts => hosts
    ).authorized?
    set_locale_for(user) do
      mail(
        :to => recipient_mail(recipient),
        :subject => _(subject),
        :importance => 'High'
      ) do |format|
        format.html { render :layout => 'application_mailer' }
      end
    end
  end

  def user_for_recipient(recipient)
    case recipient
    when Array
      User.anonymous_admin
    when User
      recipient
    else
      raise Foreman::Exception.new(N_('Cannot map recipient %s to user'), recipient.inspect)
    end
  end

  def recipient_mail(recipient)
    return recipient if recipient.is_a?(Array)
    return recipient.mail if recipient.mail.present?

    admin_email
  end

  def admin_email
    Setting[:administrator]
  end
end
