module ForemanExpireHosts
  module HostExt
    extend ActiveSupport::Concern

    included do
      after_validation :validate_expired_on

      validates :expired_on, :presence => true, :if => -> { Setting[:is_host_expiry_date_mandatory] }

      has_one :expiration_status_object, :class_name => 'HostStatus::ExpirationStatus', :foreign_key => 'host_id'

      before_validation :refresh_expiration_status

      scope :expiring, -> { where('expired_on IS NOT NULL') }
      scope :with_expire_date, ->(date) { expiring.where('expired_on = ?', date) }
      scope :expired, -> { expiring.where('expired_on < ?', Date.today) }
      scope :expiring_today, -> { expiring.with_expire_date(Date.today) }
      scope :expired_past_grace_period, -> { expiring.where('expired_on <= ?', Date.today - Setting[:days_to_delete_after_host_expiration].to_i) }

      scoped_search :on => :expired_on, :complete_value => true, :rename => :expires, :only_explicit => true
    end

    def validate_expired_on
      if self.expires?
        begin
          unless expired_on.to_s.to_date > Date.today
            errors.add(:expired_on, _('must be in the future'))
          end
        rescue StandardError => e
          errors.add(:expired_on, _('is invalid'))
        end
      end
      if self.changed.include?('expired_on')
        unless can_modify_expiry_date?
          errors.add(:expired_on, _('no permission to edit'))
        end
      end
      true
    end

    def expires?
      expired_on.present?
    end

    def expires_today?
      return false unless expires?
      expired_on.to_date == Date.today
    end

    def expired?
      return false unless expires?
      expired_on.to_date < Date.today
    end

    def expiration_grace_period_end_date
      return nil unless expires?
      expired_on + Setting[:days_to_delete_after_host_expiration].to_i
    end

    def expired_past_grace_period?
      return false unless expires?
      expiration_grace_period_end_date <= Date.today
    end

    def pending_expiration?
      return false unless expires?
      return false if expired?
      expired_on - Setting['notify1_days_before_host_expiry'].to_i <= Date.today
    end

    def can_modify_expiry_date?
      return true if new_record?
      return true if defined?(Rails::Console)
      return true unless User.current
      return true if Authorizer.new(User.current).can?(:edit_host_expiry, self)
      return true if self.owner_type.nil? || self.owner.nil?
      Setting[:can_owner_modify_host_expiry_date] &&
        ((self.owner_type == 'User' && self.owner == User.current) ||
         (self.owner_type == 'Usergroup' && self.owner.all_users.include?(User.current)))
    end

    private

    def refresh_expiration_status
      self.get_status(HostStatus::ExpirationStatus).refresh
    end
  end
end
