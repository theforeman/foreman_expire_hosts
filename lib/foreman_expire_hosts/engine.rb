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

    initializer 'foreman_expire_hosts.register_plugin', :before => :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_expire_hosts do
        requires_foreman '>= 3.0.0'
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

        Setting::BLANK_ATTRS << 'host_expiry_email_recipients'

        settings do
          category(:expire_hosts, N_('Expire Hosts')) do
            setting('is_host_expiry_date_mandatory',
                    type: :boolean,
                    description: N_('Make expiry date field mandatory on host creation/update'),
                    default: false,
                    full_name: N_('Require host expiry date'))
            setting('can_owner_modify_host_expiry_date',
                    type: :boolean,
                    description: N_('Allow host owner to modify host expiry date field. If the field is false then admin only can edit expiry field'),
                    default: false,
                    full_name: N_('Host owner can modify host expiry date'))
            setting('notify1_days_before_host_expiry',
                    type: :integer,
                    description: N_('Send first notification to owner of hosts about his hosts expiring in given days. Must be integer only'),
                    default: 7,
                    full_name: N_('First expiry notification'))
            setting('notify2_days_before_host_expiry',
                    type: :integer,
                    description: N_('Send second notification to owner of hosts about his hosts expiring in given days. Must be integer only'),
                    default: 1,
                    full_name: N_('Second expiry notification'))
            setting('days_to_delete_after_host_expiration',
                    type: :integer,
                    description: N_('Delete expired hosts after given days of hosts expiry date. Must be integer only'),
                    default: 3,
                    full_name: N_('Expiry grace period in days'))
            setting('host_expiry_email_recipients',
                    type: :string,
                    description: N_('All notifications will be delivered to its owner. If any other users/admins need to receive those expiry warning notifications then those emails can be configured comma separated here.'),
                    default: nil,
                    full_name: N_('Expiry e-mail recipients'))
          end
        end

        extend_rabl_template 'api/v2/hosts/main', 'api/v2/hosts/expiration'

        describe_host do
          multiple_actions_provider :expire_hosts_host_multiple_actions
        end
      end
    end

    config.to_prepare do
      begin
        ::Host::Managed.include ForemanExpireHosts::HostExt
        ::HostsController.prepend ForemanExpireHosts::HostControllerExtensions
        ::AuditsHelper.include ForemanExpireHosts::AuditsHelperExtensions
        ::Api::V2::HostsController.include ForemanExpireHosts::Api::V2::HostsControllerExtensions
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

  def self.logger
    Foreman::Logging.logger('foreman_expire_hosts')
  end
end
