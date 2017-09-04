module ForemanExpireHosts
  class ExpiryEditAuthorizer
    attr_accessor :user, :hosts

    def initialize(opts = {})
      self.user = opts.fetch(:user)
      self.hosts = opts.fetch(:hosts)
    end

    def authorized?
      hosts.each do |host|
        next unless user.can?(:edit_hosts, host)
        return true if user.can?(:edit_host_expiry, host)
        return true if Setting[:can_owner_modify_host_expiry_date] &&
                       ((host.owner_type == 'User' && host.owner == user) ||
                        (host.owner_type == 'Usergroup' && host.owner.all_users.include?(user)))
      end
      false
    end
  end
end
