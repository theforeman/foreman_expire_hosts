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
      require_dependency File.expand_path('../../../app/models/setting/expire_hosts.rb', __FILE__) if (Setting.table_exists? rescue(false))
    end

    initializer 'foreman_expire_hosts.register_plugin', :before => :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_expire_hosts do
        requires_foreman '>= 1.16'
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
      end
    end

    config.to_prepare do
      begin
        Host::Managed.send :include, ForemanExpireHosts::HostExt
        HostsHelper.send :include, ForemanExpireHosts::HostsHelperExtensions
        HostsController.send :prepend, ForemanExpireHosts::HostControllerExtensions
        AuditsHelper.send :include, ForemanExpireHosts::AuditsHelperExtensions
      rescue StandardError => e
        Rails.logger.warn "ForemanExpireHosts: skipping engine hook (#{e})"
      end
    end

    rake_tasks do
      Rake::Task['db:seed'].enhance do
        ForemanExpireHosts::Engine.load_seed
      end
    end

    # Precompile any JS or CSS files under app/assets/
    # If requiring files from each other, list them explicitly here to avoid precompiling the same
    # content twice.
    assets_to_precompile =
      Dir.chdir(root) do
        Dir['app/assets/javascripts/**/*', 'app/assets/stylesheets/**/*'].map do |f|
          f.split(File::SEPARATOR, 4).last
        end
      end
    initializer 'foreman_expire_hosts.assets.precompile' do |app|
      app.config.assets.precompile += assets_to_precompile
    end
    initializer 'foreman_expire_hosts.configure_assets', group: :assets do
      SETTINGS[:foreman_expire_hosts] = { assets: { precompile: assets_to_precompile } }
    end
  end
end
