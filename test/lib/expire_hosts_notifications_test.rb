require 'test_plugin_helper'
require 'notifications_test_helper'

class ExpireHostsNotificationsTest < ActiveSupport::TestCase
  include NotificationBlueprintSeeds

  setup do
    setup_settings
    ActionMailer::Base.deliveries.clear
  end

  let(:user) { FactoryGirl.create(:user, :with_usergroup, :with_mail) }
  let(:usergroup) { user.usergroups.first }

  context '#delete_expired_hosts' do
    context 'with single owner' do
      setup do
        FactoryGirl.create_list(:host, 2, :expired, :owner => user)
        FactoryGirl.create_list(:host, 2, :owner => user)
      end

      test 'should delete expired hosts' do
        assert_difference 'Host.count', -2 do
          ExpireHostsNotifications.delete_expired_hosts
        end
        assert_equal 1, ActionMailer::Base.deliveries.count
        assert_includes ActionMailer::Base.deliveries.first.subject, 'Deleted expired hosts'
      end
    end

    context 'with usergroup owner' do
      setup do
        FactoryGirl.create_list(:host, 2, :expired, :owner => usergroup)
        FactoryGirl.create_list(:host, 2, :owner => usergroup)
      end

      test 'should delete expired hosts' do
        assert_difference 'Host.count', -2 do
          ExpireHostsNotifications.delete_expired_hosts
        end
        assert_equal 1, ActionMailer::Base.deliveries.count
        assert_includes ActionMailer::Base.deliveries.first.subject, 'Deleted expired hosts'
      end
    end

    context 'without owner' do
      setup do
        FactoryGirl.create_list(:host, 2, :expired, :without_owner)
        FactoryGirl.create_list(:host, 2, :without_owner)
      end

      test 'should delete expired hosts' do
        assert_difference 'Host.count', -2 do
          ExpireHostsNotifications.delete_expired_hosts
        end
        assert_equal 1, ActionMailer::Base.deliveries.count
        assert_includes ActionMailer::Base.deliveries.first.subject, 'Deleted expired hosts'
      end
    end

    context 'with additional recipients' do
      setup do
        Setting[:host_expiry_email_recipients] = 'test@example.com, test2.example.com'
        FactoryGirl.create_list(:host, 2, :expired, :owner => user)
      end

      test 'should deliver notification to additional recipients' do
        ExpireHostsNotifications.delete_expired_hosts
        assert_equal 3, ActionMailer::Base.deliveries.count
        assert_includes ActionMailer::Base.deliveries.first.subject, 'Deleted expired hosts'
        assert_includes ActionMailer::Base.deliveries.flat_map(&:to), user.mail
        assert_includes ActionMailer::Base.deliveries.flat_map(&:to), 'test@example.com'
        assert_includes ActionMailer::Base.deliveries.flat_map(&:to), 'test2.example.com'
      end
    end
  end

  context '#stop_expired_hosts' do
    let(:power_mock) { mock('power') }
    let(:host) { FactoryGirl.create(:host, :expired, :on_compute_resource, :owner => user) }
    let(:blueprint) { NotificationBlueprint.find_by(name: 'expire_hosts_stopped_host') }
    setup do
      power_mock.stubs(:ready?).returns(true)
      host.unstub(:queue_compute)
      Host.any_instance.stubs(:power).returns(power_mock)
      FactoryGirl.create_list(:host, 2, :owner => user)
    end

    test 'should stop expired hosts' do
      power_mock.expects(:stop).returns(true)
      ExpireHostsNotifications.stop_expired_hosts
      assert_equal 1, ActionMailer::Base.deliveries.count
      assert_includes ActionMailer::Base.deliveries.first.subject, 'Stopped expired hosts'
    end

    test 'should send a ui notification per stopped host' do
      power_mock.expects(:stop).returns(true)
      assert_difference('blueprint.notifications.count', 1) do
        ExpireHostsNotifications.stop_expired_hosts
      end
    end

    test 'should send failure message if host cannot be stopped' do
      power_mock.expects(:stop).returns(false)
      ExpireHostsNotifications.stop_expired_hosts
      assert_equal 1, ActionMailer::Base.deliveries.count
      assert_includes ActionMailer::Base.deliveries.first.subject, 'Failed to stop expired hosts'
    end
  end

  context '#deliver_expiry_warning_notification' do
    let(:blueprint) { NotificationBlueprint.find_by(name: 'expire_hosts_expiry_warning') }
    let(:hosts) { FactoryGirl.create_list(:host, 2, :expires_in_a_week, :owner => user) }

    setup do
      Setting['notify1_days_before_host_expiry'] = 7
      hosts
    end

    test 'should send a ui notification per host' do
      assert_difference('blueprint.notifications.count', 2) do
        ExpireHostsNotifications.deliver_expiry_warning_notification
      end
      hosts.each do |host|
        notification = Notification.find_by(
          notification_blueprint_id: blueprint.id,
          subject_id: host.id,
          subject_type: 'Host::Base'
        )
        assert_equal 1, notification.notification_recipients.where(user_id: user.id).count
      end
    end

    test 'should redisplay read ui notification' do
      ExpireHostsNotifications.deliver_expiry_warning_notification
      notification = Notification.find_by(notification_blueprint_id: blueprint.id, subject_id: hosts.first.id)
      assert_not_nil notification
      assert_equal 1, NotificationRecipient.where(notification_id: notification.id).update_all(seen: true) # rubocop:disable Rails/SkipsModelValidations
      ExpireHostsNotifications.deliver_expiry_warning_notification
      assert_equal 1, NotificationRecipient.where(notification_id: notification.id, seen: false).count
    end

    test 'should send a single notification' do
      ExpireHostsNotifications.deliver_expiry_warning_notification
      assert_equal 1, ActionMailer::Base.deliveries.count
      assert_includes ActionMailer::Base.deliveries.first.subject, 'Expiring hosts in foreman'
    end

    test 'should send two notifications for two users' do
      owner2 = FactoryGirl.create(:user, :with_mail)
      FactoryGirl.create(:host, :expires_in_a_week, :owner => owner2)
      ExpireHostsNotifications.deliver_expiry_warning_notification
      assert_equal 2, ActionMailer::Base.deliveries.count
      assert_includes ActionMailer::Base.deliveries.first.subject, 'Expiring hosts in foreman'
      assert_includes ActionMailer::Base.deliveries.last.subject, 'Expiring hosts in foreman'
    end

    test 'should send three notifications for three users' do
      user2 = FactoryGirl.create(:user, :with_mail)
      user3 = FactoryGirl.create(:user, :with_mail, :usergroups => [usergroup])
      FactoryGirl.create(:host, :expires_in_a_week, :owner => user2)
      FactoryGirl.create(:host, :expires_in_a_week, :owner => usergroup)
      ExpireHostsNotifications.deliver_expiry_warning_notification
      assert_equal 3, ActionMailer::Base.deliveries.count
      assert_includes ActionMailer::Base.deliveries.first.subject, 'Expiring hosts in foreman'
      assert_includes ActionMailer::Base.deliveries.flat_map(&:to), user.mail
      assert_includes ActionMailer::Base.deliveries.flat_map(&:to), user2.mail
      assert_includes ActionMailer::Base.deliveries.flat_map(&:to), user3.mail
      assert_equal 1, ActionMailer::Base.deliveries.flat_map(&:subject).uniq.count
    end
  end
end
