require 'test_plugin_helper'

class ExpireHostsNotificationsTest < ActiveSupport::TestCase
  setup do
    setup_settings
    @owner = FactoryGirl.create(:user, :with_mail)
  end

  context '#delete_expired_hosts' do
    setup do
      @hosts = FactoryGirl.create_list(:host, 2, :expired, :owner => @owner)
      @unaffected_hosts = FactoryGirl.create_list(:host, 2, :owner => @owner)
    end

    test 'should delete expired hosts' do
      ExpireHostsMailer.expects(:deleted_hosts_notification).once
      assert_difference 'Host.count', -2 do
        ExpireHostsNotifications.delete_expired_hosts
      end
    end
  end

  context '#stop_expired_hosts' do
    setup do
      @power_mock = mock('power')
      @power_mock.stubs(:ready?).returns(true)
      @host = FactoryGirl.create(:host, :expired, :on_compute_resource, :owner => @owner)
      @host.unstub(:queue_compute)
      Host.any_instance.stubs(:power).returns(@power_mock)
      @unaffected_hosts = FactoryGirl.create_list(:host, 2, :owner => @owner)
    end

    test 'should stop expired hosts' do
      @power_mock.expects(:stop).returns(true)
      ExpireHostsMailer.expects(:stopped_hosts_notification).once
      ExpireHostsNotifications.stop_expired_hosts
    end

    test 'should send failure message if host cannot be stopped' do
      @power_mock.expects(:stop).returns(false)
      ExpireHostsMailer.expects(:failed_to_stop_hosts_notification).once
      ExpireHostsNotifications.stop_expired_hosts
    end
  end

  context '#deliver_expiry_warning_notification' do
    setup do
      Setting['notify1_days_before_host_expiry'] = 7
      @hosts = FactoryGirl.create_list(:host, 2, :expires_in_a_week, :owner => @owner)
    end

    test 'should send a single notification' do
      ExpireHostsMailer.expects(:expiry_warning_notification).once
      ExpireHostsNotifications.deliver_expiry_warning_notification
    end

    test 'should send two notifications for two users' do
      owner2 = FactoryGirl.create(:user, :with_mail)
      FactoryGirl.create(:host, :expires_in_a_week, :owner => owner2)
      ExpireHostsMailer.expects(:expiry_warning_notification).twice
      ExpireHostsNotifications.deliver_expiry_warning_notification
    end
  end

  context '#catch_delivery_errors' do
    test 'should catch and log errors' do
      host1 = OpenStruct.new(:name => 'Alpha')
      host2 = OpenStruct.new(:name => 'Bravo')
      hosts = [host1, host2]
      Foreman::Logging.expects(:exception).with('failure for Hosts Alpha and Bravo', anything)
      ExpireHostsNotifications.catch_delivery_errors('failure', hosts) do
        raise 'Test'
      end
    end
  end
end
