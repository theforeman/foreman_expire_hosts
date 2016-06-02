require 'test_plugin_helper'

class ForemanExpireHostsHostExtTest < ActiveSupport::TestCase
  setup do
    User.current = FactoryGirl.build(:user, :admin)
    setup_settings
  end

  context 'without required expiration date' do
    setup do
      Setting[:is_host_expiry_date_mandatory] = false
    end

    test 'should not require expired on' do
      host = FactoryGirl.build(:host)
      assert host.valid?, "Should be valid without expiration date: : #{host.errors.messages}"
    end
  end

  context 'with required expiration date' do
    setup do
      Setting[:is_host_expiry_date_mandatory] = true
    end

    test 'should require expired on' do
      host = FactoryGirl.build(:host)
      refute host.valid?, "Can not be valid without expiration date: #{host.errors.messages}"
      assert_includes host.errors.messages.keys, :expired_on
    end
  end

  context 'a host without expiration' do
    setup do
      @host = FactoryGirl.build(:host)
    end

    test 'should not expire' do
      refute @host.expires?
    end

    test 'should not expire today' do
      refute @host.expires_today?
    end

    test 'should not be expired' do
      refute @host.expired?
    end

    test 'should not be expired past grace period' do
      refute @host.expired_past_grace_period?
    end

    test 'should not be pending expiration' do
      refute @host.pending_expiration?
    end
  end

  context 'a expired host' do
    setup do
      @host = FactoryGirl.build(:host, :expired)
    end

    test 'should expire' do
      assert @host.expires?
    end

    test 'should not expire today' do
      refute @host.expires_today?
    end

    test 'should be expired' do
      assert @host.expired?
    end

    test 'should be expired past grace period' do
      assert @host.expired_past_grace_period?
    end

    test 'should not be pending expiration' do
      refute @host.pending_expiration?
    end
  end

  context 'a host expiring today' do
    setup do
      @host = FactoryGirl.build(:host, :expires_today)
    end

    test 'should expire' do
      assert_equal Date.today, @host.expired_on
      assert @host.expires?
    end

    test 'should expire today' do
      assert @host.expires_today?
    end

    test 'should not be expired' do
      refute @host.expired?
    end

    test 'should not be expired past grace period' do
      refute @host.expired_past_grace_period?
    end

    test 'should be pending expiration' do
      assert @host.pending_expiration?
    end
  end

  context 'a host in grace period' do
    setup do
      @host = FactoryGirl.build(:host, :expired_grace)
    end

    test 'should expire' do
      assert @host.expires?
    end

    test 'should not expire today' do
      refute @host.expires_today?
    end

    test 'should be expired' do
      assert @host.expired?
    end

    test 'should not be expired past grace period' do
      refute @host.expired_past_grace_period?
    end

    test 'should not be pending expiration' do
      refute @host.pending_expiration?
    end
  end
end
