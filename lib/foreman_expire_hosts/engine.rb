require 'deface'

module ForemanExpireHosts
  class Engine < ::Rails::Engine

    # engine_name :foreman_expire_hosts

    config.to_prepare do

      if SETTINGS[:version].to_s.to_f >= 1.2
        # Foreman 1.2
        Host::Managed.send :include, HostExpiredOnValidator
      else
        # Foreman < 1.2
        Host.send :include, HostExpiredOnValidator
      end
    end

    initializer 'foreman_expire_hosts.register_plugin', :after => :finisher_hook do |app|
      Foreman::Plugin.register :foreman_expire_hosts do
        app.config.paths['db/migrate'] += ForemanExpireHosts::Engine.paths['db/migrate'].existent
      end
    end

    initializer 'foreman_expire_hosts.helper' do |app|
      ActionView::Base.send :include, ForemanExpireHosts::HostExpiredOnHelper
    end

  end
end
