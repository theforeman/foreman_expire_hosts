# frozen_string_literal: true

require 'test_plugin_helper'

class HostsControllerTest < ActionController::TestCase
  setup do
    User.current = users(:admin)
    disable_orchestration
    setup_settings
  end

  describe 'host creation' do
    test 'new host with expiration date' do
      expiration_date = Date.today + 14
      assert_difference 'Host.count' do
        post :create, params: { :host => {
          :name => 'myotherfullhost',
          :mac => 'aabbecddee06',
          :ip => '2.3.4.125',
          :domain_id => domains(:mydomain).id,
          :operatingsystem_id => operatingsystems(:redhat).id,
          :architecture_id => architectures(:x86_64).id,
          :environment_id => environments(:production).id,
          :subnet_id => subnets(:one).id,
          :medium_id => media(:one).id,
          :pxe_loader => 'Grub2 UEFI',
          :realm_id => realms(:myrealm).id,
          :disk => 'empty partition',
          :puppet_proxy_id => smart_proxies(:puppetmaster).id,
          :root_pass => 'xybxa6JUkz63w',
          :location_id => taxonomies(:location1).id,
          :organization_id => taxonomies(:organization1).id,
          :expired_on => expiration_date
        } }, session: set_session_user
      end
      h = Host.search_for('myotherfullhost').first
      assert_equal expiration_date, h.expired_on
      assert_redirected_to host_url(assigns['host'])
    end
  end

  describe 'updating a host' do
    let(:host) { FactoryBot.create(:host) }

    test 'should add expiration date to host' do
      expiration_date = Date.today + 14
      put :update, params: { :id => host.name, :host => { :expired_on => expiration_date } }, session: set_session_user
      h = Host.find(host.id)
      assert_equal expiration_date, h.expired_on
    end
  end

  describe 'setting expiration date on multiple hosts' do
    before do
      as_admin do
        @hosts = FactoryBot.create_list(:host, 2, :with_puppet)
      end
      @request.env['HTTP_REFERER'] = hosts_path
    end

    test 'show a host selection' do
      host_ids = @hosts.map(&:id)
      post :select_multiple_expiration, params: { :host_ids => host_ids }, session: set_session_user, xhr: true
      assert_response :success
      @hosts.each do |host|
        assert response.body =~ /#{host.name}/m
      end
    end

    test 'should set expiration date' do
      expiration_date = Date.today + 14
      params = { :host_ids => @hosts.map(&:id),
                 :host => { 'expired_on' => expiration_date.strftime('%Y-%m-%d') } }

      post :update_multiple_expiration, params: params, session: set_session_user.merge(:user => users(:admin).id)

      assert_empty flash[:error]

      @hosts.each do |host|
        assert_equal expiration_date, host.reload.expired_on
      end
    end

    test 'should clear the expiration date of multiple hosts' do
      params = { :host_ids => @hosts.map(&:id),
                 :host => { :expired_on => '' } }

      post :update_multiple_expiration, params: params, session: set_session_user.merge(:user => users(:admin).id)

      assert_empty flash[:error]

      @hosts.each do |host|
        assert_nil host.reload.expired_on
      end
    end
  end
end
