module ForemanExpireHosts
  module HostExt
    extend ActiveSupport::Concern

    included do
      after_validation :validate_expired_on
      attr_accessible :expired_on

      validates :expired_on, :presence => true, :if => -> { Setting[:is_host_expiry_date_mandatory] }

      has_one :expiration_status_object, :class_name => 'HostStatus::ExpirationStatus', :foreign_key => 'host_id'

      before_validation :refresh_expiration_status

      scope :expiring, -> { where('expired_on IS NOT NULL') }
      scope :with_expire_date, ->(date) { expiring.where('expired_on = ?', date) }
      scope :expired, -> { expiring.where('expired_on < ?', Date.today) }
      scope :expiring_today, -> { expiring.with_expire_date(Date.today) }
      scope :expired_past_grace_period, -> { expiring.where('expired_on < ?', Date.today + Setting[:days_to_delete_after_host_expiration].to_i) }

      scoped_search :on => :expired_on, :complete_value => :true, :rename => :expires
    end

    def validate_expired_on
      if self.expires?
        begin
          unless expired_on.to_s.to_date > Date.today
            errors.add(:expired_on, _('must be in the future'))
          end
        rescue => e
          errors.add(:expired_on, _('is invalid'))
        end
      end
      if self.changed.include?('expired_on')
        unless can_modify_expiry_date?
          errors.add(:expired_on, _('no permission to edit'))
        end
      end
      errors[:expired_on].empty?
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
      expiration_grace_period_end_date < Date.today
    end

    def pending_expiration_start_date
      Date.today - Setting['notify1_days_before_host_expiry'].to_i
    end

    def pending_expiration?
      return false unless expires?
      return false if expired?
      pending_expiration_start_date <= expired_on
    end

    def can_modify_expiry_date?
      (new_record? || (defined?(Rails::Console) || (User.current && (User.current.admin || (Setting[:can_owner_modify_host_expiry_date] || ((owner_type == 'User' && owner.id == User.current.id) || (owner_type == 'Usergroup' && owner.users.map(&:id).include?(User.current.id))))))))
    end

    private

    def refresh_expiration_status
      self.get_status(HostStatus::ExpirationStatus).refresh
    end
  end
end
