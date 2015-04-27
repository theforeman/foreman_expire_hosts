require 'deface'
require 'bootstrap-datepicker-rails'

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

    initializer 'foreman_expire_hosts.assets.precompile' do |app|
      app.config.assets.precompile += %w(
        'foreman_expire_hosts/application.js',
        'foreman_expire_hosts/application.scss'
      )
    end
  end
end
