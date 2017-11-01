# Tasks
namespace :expired_hosts do
  desc 'Delete all expired hosts, send notification email about expiring hosts'
  task :deliver_notifications => :environment do
    User.as_anonymous_admin do
      ExpireHostsNotifications.delete_expired_hosts
      ExpireHostsNotifications.stop_expired_hosts
      ExpireHostsNotifications.deliver_expiry_warning_notification(1)
      ExpireHostsNotifications.deliver_expiry_warning_notification(2)
    end
  end
end

# Tests
namespace :test do
  desc 'Test ForemanExpireHosts'
  Rake::TestTask.new(:foreman_expire_hosts) do |t|
    test_dir = File.join(File.dirname(__FILE__), '../..', 'test')
    t.libs << ['test', test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
    t.warning = false
  end
end

namespace :foreman_expire_hosts do
  task :rubocop do
    begin
      require 'rubocop/rake_task'
      RuboCop::RakeTask.new(:rubocop_foreman_expire_hosts) do |task|
        task.patterns = ["#{ForemanExpireHosts::Engine.root}/app/**/*.rb",
                         "#{ForemanExpireHosts::Engine.root}/lib/**/*.rb",
                         "#{ForemanExpireHosts::Engine.root}/test/**/*.rb"]
      end
    rescue StandardError
      puts 'Rubocop not loaded.'
    end

    Rake::Task['rubocop_foreman_expire_hosts'].invoke
  end
end

Rake::Task[:test].enhance ['test:foreman_expire_hosts']

load 'tasks/jenkins.rake'
if Rake::Task.task_defined?(:'jenkins:unit')
  Rake::Task['jenkins:unit'].enhance ['test:foreman_expire_hosts', 'foreman_expire_hosts:rubocop']
end
