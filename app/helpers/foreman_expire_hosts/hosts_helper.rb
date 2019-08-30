# frozen_string_literal: true

module ForemanExpireHosts
  module HostsHelper
    def expire_hosts_host_multiple_actions
      actions = []
      if authorized_for(:controller => :hosts, :action => :select_multiple_expiration)
        actions << {
          action: [_('Change Expiration'), select_multiple_expiration_hosts_path],
          priority: 200
        }
      end
      actions
    end
  end
end
