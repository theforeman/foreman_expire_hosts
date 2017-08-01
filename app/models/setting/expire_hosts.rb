class Setting::ExpireHosts < Setting
  def self.load_defaults
    # Check the table exists
    return unless super

    self.transaction do
      [
        self.set('is_host_expiry_date_mandatory', N_('Make expiry date field mandatory on host creation/update'), false, N_('Require host expiry date')),
        self.set('can_owner_modify_host_expiry_date', N_('Allow host owner to modify host expiry date field. If the field is false then admin only can edit expiry field'), false, N_('Host owner can modify host expiry date')),
        self.set('notify1_days_before_host_expiry', N_('Send first notification to owner of hosts about his hosts expiring in given days. Must be integer only'), 7, N_('First expiry notification')),
        self.set('notify2_days_before_host_expiry', N_('Send second notification to owner of hosts about his hosts expiring in given days. Must be integer only'), 1, N_('Second expiry notification')),
        self.set('days_to_delete_after_host_expiration', N_('Delete expired hosts after given days of hosts expiry date. Must be integer only'), 3, N_('Expiry grace period in days')),
        self.set('host_expiry_email_recipients', N_('All notifications will be delivered to its owner. If any other users/admins need to receive those expiry wanting notifications then those emails can be configured here. This must be string and multiple emails can give with coma(,) separated'), 'foreman-admin@your_foreman.com', N_('Expiry e-mail recipients'))
      ].each { |s| self.create! s.update(:category => 'Setting::ExpireHosts') }
    end

    true
  end
end
