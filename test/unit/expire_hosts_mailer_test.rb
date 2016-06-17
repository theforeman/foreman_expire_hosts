require 'test_plugin_helper'

class ExpireHostMailerTest < ActionMailer::TestCase
  setup do
    setup_settings
    @emails = ['test@example.com']
    @hosts = FactoryGirl.create_list(:host, 2, :managed)
  end

  context 'deleted hosts notification' do
    setup do
      @mail = ExpireHostsMailer.deleted_hosts_notification(@emails, @hosts).deliver
    end

    test 'subject should be set' do
      refute_nil @mail.subject
      assert_includes @mail.subject, 'Deleted expired hosts in Foreman'
    end
  end

  context 'failed to delete hosts notification' do
    setup do
      @mail = ExpireHostsMailer.failed_to_delete_hosts_notification(@emails, @hosts).deliver
    end

    test 'subject should be set' do
      refute_nil @mail.subject
      assert_includes @mail.subject, 'Failed to delete expired hosts in Foreman'
    end
  end

  context 'stopped hosts notification' do
    setup do
      @mail = ExpireHostsMailer.stopped_hosts_notification(@emails, Date.today, @hosts).deliver
    end

    test 'subject should be set' do
      refute_nil @mail.subject
      assert_includes @mail.subject, 'Stopped expired hosts in Foreman'
    end
  end

  context 'failed to stop hosts notification' do
    setup do
      @mail = ExpireHostsMailer.failed_to_stop_hosts_notification(@emails, @hosts).deliver
    end

    test 'subject should be set' do
      refute_nil @mail.subject
      assert_includes @mail.subject, 'Failed to stop expired hosts in Foreman'
    end
  end

  context 'expiry warning notification' do
    setup do
      @mail = ExpireHostsMailer.expiry_warning_notification(@emails, Date.today, @hosts).deliver
    end

    test 'subject should be set' do
      refute_nil @mail.subject
      assert_includes @mail.subject, 'Expiring hosts in foreman'
    end
  end
end
