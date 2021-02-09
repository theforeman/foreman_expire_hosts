# frozen_string_literal: true

module ForemanExpireHosts
  module HostControllerExtensions
    def self.prepended(base)
      base.class_eval do
        before_action :validate_multiple_expiration, :only => :update_multiple_expiration
        before_action :find_multiple_with_expire_hosts, :only => [:select_multiple_expiration, :update_multiple_expiration]
        alias_method :find_multiple_with_expire_hosts, :find_multiple
      end
    end

    def select_multiple_expiration; end

    def update_multiple_expiration
      failed_hosts = {}

      @hosts.each do |host|
        host.expired_on = expiration_date
        host.save!
      rescue StandardError => e
        failed_hosts[host.name] = e
        message = if expiration_date.present?
                    _('Failed to set expiration date for %{host} to %{expiration_date}.') % { :host => host, :expiration_date => l(expiration_date) }
                  else
                    _('Failed to clear expiration date for %s.') % host
                  end
        Foreman::Logging.exception(message, e)
      end

      if failed_hosts.empty?
        if expiration_date.present?
          success _('The expiration date of the selected hosts was set to %s.') % l(expiration_date)
        else
          success _('The expiration date of the selected hosts was cleared.')
        end
      else
        error n_('The expiration date could not be set for host: %s.',
                 'The expiration date could not be set for hosts: %s.',
                 failed_hosts.count) % failed_hosts.map { |h, err| "#{h} (#{err})" }.to_sentence
      end
      redirect_back_or_to hosts_path
    end

    private

    def validate_multiple_expiration
      expiration_date
    rescue ArgumentError
      error _('Invalid expiration date!')
      redirect_to(hosts_path) && (return false)
    end

    def expiration_date
      @expiration_date ||= begin
        expired_on = params[:host][:expired_on]
        expired_on.present? ? Date.parse(expired_on) : nil
      end
    end

    def action_permission
      case params[:action]
      when 'select_multiple_expiration', 'update_multiple_expiration'
        :edit
      else
        super
      end
    end
  end
end
