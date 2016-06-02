require 'test_plugin_helper'

class HostsControllerTest < ActionController::TestCase
  setup do
    setup_settings
  end

  describe 'setting expiration date on multiple hosts' do
    before do
      as_admin do
        @hosts = FactoryGirl.create_list(:host, 2, :with_puppet)
      end
      @request.env['HTTP_REFERER'] = hosts_path
    end

    test 'should set expiration date' do
      expiration_date = Date.today + 14
      params = { :host_ids => @hosts.map(&:id),
                 :host => { :expired_on => expiration_date } }

      post :update_multiple_expiration, params,
           set_session_user.merge(:user => users(:admin).id)

      assert_empty flash[:error]

      @hosts.each do |host|
        assert_equal expiration_date, host.reload.expired_on
      end
    end

    test 'should clear the expiration date of multiple hosts' do
      params = { :host_ids => @hosts.map(&:id),
                 :host => { :expired_on => '' } }

      post :update_multiple_expiration, params,
           set_session_user.merge(:user => users(:admin).id)

      assert_empty flash[:error]

      @hosts.each do |host|
        assert_equal nil, host.reload.expired_on
      end
    end
  end
end
