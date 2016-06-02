require 'test_plugin_helper'

class ExpirationStatusTest < ActiveSupport::TestCase
  def setup
    @host = FactoryGirl.build(:host)
    @status = HostStatus::ExpirationStatus.new(:host => @host)
  end

  test 'is valid' do
    assert_valid @status
  end

  test '#to_label changes based on expiration date' do
    @host.expired_on = '23/11/1900'
    assert_equal 'Expired on 1900-11-23', @status.to_label

    @host.expired_on = Date.today
    assert_equal 'Expires today', @status.to_label
  end

  test '#relevant? is only for expiring hosts' do
    @host.expired_on = '23/11/1900'
    assert @status.relevant?

    @host.expired_on = nil
    refute @status.relevant?
  end
end
