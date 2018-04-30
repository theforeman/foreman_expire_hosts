require 'deface'
require 'bootstrap-datepicker-rails'

module ForemanExpireHosts
  class Engine < ::Rails::Engine
    engine_name 'foreman_expire_hosts'

    config.autoload_paths += Dir["#{config.root}/lib"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/helpers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/services"]

    # Add any db migrations
    initializer 'foreman_plugin_template.load_app_instance_data' do |app|
      ForemanExpireHosts::Engine.paths['db/migrate'].existent.each do |path|
        app.config.paths['db/migrate'] << path
      end
    end

    initializer 'foreman_expire_hosts.load_default_settings', :before => :load_config_initializers do
      require_dependency File.expand_path('../../app/models/setting/expire_hosts.rb', __dir__) if (Setting.table_exists? rescue(false))
    end

    initializer 'foreman_expire_hosts.register_plugin', :before => :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_expire_hosts do
        requires_foreman '>= 1.17'
        register_custom_status HostStatus::ExpirationStatus

        # strong parameters
        parameter_filter Host::Managed, :expired_on

        security_block :foreman_expire_hosts do
          permission :edit_host_expiry,
                     {},
                     :resource_type => 'Host'
          permission :edit_hosts,
                     { :hosts => [:select_multiple_expiration, :update_multiple_expiration] },
                     :resource_type => 'Host'
        end

        extend_rabl_template 'api/v2/hosts/main', 'api/v2/hosts/expiration'
      end
    end

    config.to_prepare do
      begin
        Host::Managed.send :include, ForemanExpireHosts::HostExt
        HostsHelper.send :include, ForemanExpireHosts::HostsHelperExtensions
        HostsController.send :prepend, ForemanExpireHosts::HostControllerExtensions
        AuditsHelper.send :include, ForemanExpireHosts::AuditsHelperExtensions
        ::Api::V2::HostsController.send :include, ForemanExpireHosts::Api::V2::HostsControllerExtensions
      rescue StandardError => e
        Rails.logger.warn "ForemanExpireHosts: skipping engine hook (#{e})"
      end
    end

    rake_tasks do
      Rake::Task['db:seed'].enhance do
        ForemanExpireHosts::Engine.load_seed
      end
    end
  end
end
