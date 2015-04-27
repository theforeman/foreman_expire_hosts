#require 'expire_hosts_notifications'

namespace :expired_hosts do

  desc 'Delete all expired hosts, send notification email about expiring hosts'
  task :deliver_notifications => :environment do
    if Host.column_names.include?('expired_on')
      ExpireHostsNotifications.delete_expired_hosts
      ExpireHostsNotifications.stop_expired_hosts
      ExpireHostsNotifications.deliver_expiry_warning_notification(1)
      ExpireHostsNotifications.deliver_expiry_warning_notification(2)
    else
      Rake::Task['foreman_expire_hosts:add_column'].invoke
      Host.reset_column_information
      Rake::Task['foreman_expire_hosts:check_expired_hosts'].invoke
    end
  end


  desc 'Create expired_on column to hosts table'
  task :add_column => :environment do
    unless ActiveRecord::Base.connection.column_exists?(:hosts, :expired_on)
      ActiveRecord::Base.connection.add_column(:hosts, :expired_on, :date)
    end
  end

  desc 'Remove expired_on column from hosts table'
  task :remove_column => :environment do
    if ActiveRecord::Base.connection.column_exists?(:hosts, :expired_on)
      ActiveRecord::Base.connection.remove_column(:hosts, :expired_on)
    end
  end

end