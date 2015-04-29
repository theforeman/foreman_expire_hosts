#require 'expire_hosts_notifications'

namespace :expired_hosts do

  desc 'Delete all expired hosts, send notification email about expiring hosts'
  task :deliver_notifications => :environment do
    ExpireHostsNotifications.delete_expired_hosts
    ExpireHostsNotifications.stop_expired_hosts
    ExpireHostsNotifications.deliver_expiry_warning_notification(1)
    ExpireHostsNotifications.deliver_expiry_warning_notification(2)
  end

end