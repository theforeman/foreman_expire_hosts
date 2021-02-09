# frozen_string_literal: true

require 'deface'

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
        requires_foreman '>= 2.1'
        register_custom_status HostStatus::ExpirationStatus

        # strong parameters
        parameter_filter Host::Managed, :expired_on

        security_block :foreman_expire_hosts do
          permission :edit_host_expiry,
                     {},
                     :resource_type => 'Host'
        end

        # Extend built in permissions
        Foreman::AccessControl.permission(:edit_hosts).actions.concat [
          'hosts/select_multiple_expiration',
          'hosts/update_multiple_expiration'
        ]

        extend_rabl_template 'api/v2/hosts/main', 'api/v2/hosts/expiration'

        describe_host do
          multiple_actions_provider :expire_hosts_host_multiple_actions
        end
      end
    end

    config.to_prepare do
      ::Host::Managed.include ForemanExpireHosts::HostExt
      ::HostsHelper.include ForemanExpireHosts::HostsHelperExtensions
      ::HostsController.prepend ForemanExpireHosts::HostControllerExtensions
      ::AuditsHelper.include ForemanExpireHosts::AuditsHelperExtensions
      ::Api::V2::HostsController.include ForemanExpireHosts::Api::V2::HostsControllerExtensions
    rescue StandardError => e
      Rails.logger.warn "ForemanExpireHosts: skipping engine hook (#{e})"
    end

    rake_tasks do
      Rake::Task['db:seed'].enhance do
        ForemanExpireHosts::Engine.load_seed
      end
    end
  end

  def self.logger
    Foreman::Logging.logger('foreman_expire_hosts')
  end
end
