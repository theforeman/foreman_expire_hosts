module HostStatus
  class ExpirationStatus < HostStatus::Status
    OK = 0
    EXPIRED = 1
    IN_GRACE_PERIOD = 2
    EXPIRES_TODAY = 3
    PENDING = 4

    def self.status_name
      N_('Expiration Status')
    end

    def to_status(_options = {})
      return EXPIRES_TODAY if host.expires_today?
      return EXPIRED if host.expired_past_grace_period?
      return IN_GRACE_PERIOD if host.expired?
      return PENDING if host.pending_expiration?
      OK
    end

    def to_global(_options = {})
      case to_status
      when OK
        HostStatus::Global::OK
      when EXPIRES_TODAY
        HostStatus::Global::WARN
      when PENDING
        HostStatus::Global::WARN
      when IN_GRACE_PERIOD
        HostStatus::Global::ERROR
      when EXPIRED
        HostStatus::Global::ERROR
      else
        HostStatus::Global::OK
      end
    end

    def to_label(_options = {})
      case to_status
      when OK
        N_('Expires on %s') % I18n.l(host.expired_on)
      when EXPIRES_TODAY
        N_('Expires today')
      when IN_GRACE_PERIOD
        N_('Expired on %s, in grace period') % I18n.l(host.expired_on)
      when EXPIRED
        N_('Expired on %s') % I18n.l(host.expired_on)
      else
        N_('Pending expiration on %s') % I18n.l(host.expired_on)
      end
    end

    def relevant?(options = {})
      host.expires?
    end
  end
end
