module ForemanExpireHosts
  module HostControllerExtensions
    extend ActiveSupport::Concern

    included do
      before_filter :validate_multiple_expiration, :only => :update_multiple_expiration
      before_filter :find_multiple_with_expire_hosts, :only => [:select_multiple_expiration, :update_multiple_expiration]
      alias_method :find_multiple_with_expire_hosts, :find_multiple
    end

    def select_multiple_expiration
    end

    def update_multiple_expiration
      expiration_date = params[:host][:expired_on]
      expiration_date = Date.parse(expiration_date) if expiration_date.present?

      failed_hosts = {}

      @hosts.each do |host|
        begin
          host.expired_on = expiration_date
          host.save!
        rescue => error
          failed_hosts[host.name] = error
          message = if expiration_date.present?
                      _('Failed to set expiration date for %{host} to %{expiration_date}.') % {:host => host, :expiration_date => l(expiration_date)}
                    else
                      _('Failed to clear expiration date for %s.') % host
                    end
          Foreman::Logging.exception(message, error)
        end
      end

      if failed_hosts.empty?
        if expiration_date.present?
          notice _('The expiration date of the selected hosts was set to %s.') % l(expiration_date)
        else
          notice _('The expiration date of the selected hosts was cleared.')
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
      if params[:host].nil? || (expiration_date = params[:host][:expired_on]).nil?
        error _('No expiration date selected!')
        redirect_to(select_multiple_expiration_hosts_path) && (return false)
      end
      begin
        Date.parse(expiration_date) if expiration_date.present?
      rescue ArgumentError
        error _('Invalid expiration date!')
        redirect_to(select_multiple_expiration_hosts_path) && (return false)
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
