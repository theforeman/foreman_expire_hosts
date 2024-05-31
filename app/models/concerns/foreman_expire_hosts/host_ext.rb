# frozen_string_literal: true

module ForemanExpireHosts
  module HostExt
    extend ActiveSupport::Concern

    included do
      after_validation :validate_expired_on

      validates :expired_on, presence: true, if: -> { Setting[:is_host_expiry_date_mandatory] }

      has_one :expiration_status_object, class_name: 'HostStatus::ExpirationStatus', foreign_key: 'host_id',
                                         inverse_of: :host

      before_validation :refresh_expiration_status

      scope :expiring, -> { where('expired_on IS NOT NULL') }
      scope :with_expire_date, ->(date) { expiring.where('expired_on = ?', date) }
      scope :expired, -> { expiring.where('expired_on <= ?', Date.today) }
      scope :expiring_today, -> { expiring.with_expire_date(Date.today) }
      scope :expired_past_grace_period, lambda {
                                          expiring.where('expired_on <= ?', Date.today - Setting[:days_to_delete_after_host_expiration].to_i)
                                        }

      scoped_search on: :expired_on, complete_value: true, rename: :expires, only_explicit: true
    end

    def validate_expired_on
      if expires?
        begin
          errors.add(:expired_on, _('must be in the future')) unless expired_on.to_s.to_date > Date.today
        rescue StandardError
          errors.add(:expired_on, _('is invalid'))
        end
      end
      errors.add(:expired_on, _('no permission to edit')) if changed.include?('expired_on') && !can_modify_expiry_date?
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

      expired_on.to_date + Setting[:days_to_delete_after_host_expiration].to_i.days
    end

    def expired_past_grace_period?
      return false unless expires?

      expiration_grace_period_end_date.to_date <= Date.today
    end

    def pending_expiration?
      return false unless expires?
      return false if expired?

      expired_on.to_date - Setting['notify1_days_before_host_expiry'].to_i.days <= Date.today
    end

    def can_modify_expiry_date?
      return true if new_record?
      return true if defined?(Rails::Console)
      return true unless User.current
      return true if Authorizer.new(User.current).can?(:edit_host_expiry, self)
      return true if owner_type.nil? || owner.nil?

      Setting[:can_owner_modify_host_expiry_date] &&
        ((owner_type == 'User' && owner == User.current) ||
         (owner_type == 'Usergroup' && owner.all_users.include?(User.current)))
    end

    private

    def refresh_expiration_status
      get_status(HostStatus::ExpirationStatus).refresh
    end
  end
end
