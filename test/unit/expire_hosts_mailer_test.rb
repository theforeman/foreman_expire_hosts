# frozen_string_literal: true

require 'test_plugin_helper'

class ExpireHostMailerTest < ActionMailer::TestCase
  let(:recipient) { FactoryBot.create(:user, :with_mail) }
  let(:hosts) { FactoryBot.create_list(:host, 2, :managed) }

  context 'deleted hosts notification' do
    let(:mail) { ExpireHostsMailer.deleted_hosts_notification(recipient, hosts).deliver_now }

    test 'subject should be set' do
      assert_includes mail.subject, 'Deleted expired hosts in Foreman'
    end

    test 'recipient should be user mail address' do
      assert_equal [recipient.mail], mail.to
    end
  end

  context 'failed to delete hosts notification' do
    let(:mail) { ExpireHostsMailer.failed_to_delete_hosts_notification(recipient, hosts).deliver_now }

    test 'subject should be set' do
      assert_includes mail.subject, 'Failed to delete expired hosts in Foreman'
    end
  end

  context 'stopped hosts notification' do
    let(:mail) { ExpireHostsMailer.stopped_hosts_notification(recipient, Date.today, hosts).deliver_now }

    test 'subject should be set' do
      assert_includes mail.subject, 'Stopped expired hosts in Foreman'
    end

    test 'should include a deletion date' do
      assert_includes mail.body, "These hosts will be destroyed on #{Date.today}."
    end

    test 'should show mitigation text if authorized' do
      ForemanExpireHosts::ExpiryEditAuthorizer.any_instance.stubs(:authorized?).returns(true)
      assert_includes mail.body.to_s, 'Please change their expiry date'
    end

    test 'should not show mitigation text if not authorized' do
      ForemanExpireHosts::ExpiryEditAuthorizer.any_instance.stubs(:authorized?).returns(false)
      assert_not_includes mail.body.to_s, 'Please change their expiry date'
    end
  end

  context 'failed to stop hosts notification' do
    let(:mail) { ExpireHostsMailer.failed_to_stop_hosts_notification(recipient, hosts).deliver_now }

    test 'subject should be set' do
      assert_includes mail.subject, 'Failed to stop expired hosts in Foreman'
    end
  end

  context 'expiry warning notification' do
    let(:mail) { ExpireHostsMailer.expiry_warning_notification(recipient, Date.today, hosts).deliver_now }

    test 'subject should be set' do
      assert_includes mail.subject, 'Expiring hosts in foreman'
    end

    test 'should show mitigation text if authorized' do
      ForemanExpireHosts::ExpiryEditAuthorizer.any_instance.stubs(:authorized?).returns(true)
      assert_includes mail.body.to_s, 'Please change their expiry date'
    end

    test 'should not show mitigation text if not authorized' do
      ForemanExpireHosts::ExpiryEditAuthorizer.any_instance.stubs(:authorized?).returns(false)
      assert_not_includes mail.body.to_s, 'Please change their expiry date'
    end
  end

  context 'user without mail address' do
    let(:recipient) { FactoryBot.create(:user) }
    let(:mail) { ExpireHostsMailer.expiry_warning_notification(recipient, Date.today, hosts).deliver_now }

    test 'mail is delivered to admin address' do
      assert_nil recipient.mail
      assert_equal [Setting[:administrator]], mail.to
    end
  end
end
