require 'deface'
require 'foreman_expire_hosts'
require 'deface'

module ForemanExpireHosts
  #Inherit from the Rails module of the parent app (Foreman), not the plugin.
  #Thus, inhereits from ::Rails::Engine and not from Rails::Engine
  class Engine < ::Rails::Engine

    config.to_prepare do
      
      if SETTINGS[:version].to_s.to_f >= 1.2
        # Foreman 1.2
        Host::Managed.send :include, HostExpiredOnValidator
      else
        # Foreman < 1.2
        Host.send :include, HostExpiredOnValidator
      end  
    end

    initializer 'foreman_expire_hosts.register_plugin', :after=> :finisher_hook do |app|
      Foreman::Plugin.register :foreman_expire_hosts do
      end
    end

    initializer 'foreman_expire_hosts.helper' do |app|
      ActionView::Base.send :include, ForemanExpireHosts::HostExpiredOnHelper
    end

  end
end
