# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanExpireHosts
  class ExpiryEditAuthorizerTest < ActiveSupport::TestCase
    let(:hosts) { FactoryBot.create_list(:host, 2) }
    let(:authorizer) { ExpiryEditAuthorizer.new(hosts: hosts, user: user) }

    context 'with admin user' do
      let(:user) { FactoryBot.create(:user, :admin) }
      test 'should be authorized' do
        assert_equal true, authorizer.authorized?
      end
    end

    context 'with limited permissions' do
      let(:user_role) { FactoryBot.create(:user_user_role) }
      let(:user) { user_role.owner }
      let(:role) { user_role.role }
      let(:edit_expiry_permission) { Permission.find_by(name: 'edit_host_expiry') }
      let(:edit_permission) { Permission.find_by(name: 'edit_hosts') }

      context 'with edit_hosts and edit_host_expiry permission' do
        test 'should be authorized' do
          FactoryBot.create(:filter, role: role, permissions: [edit_permission, edit_expiry_permission])
          assert_equal true, authorizer.authorized?
        end
      end

      context 'with edit_hosts and owner permission' do
        setup do
          FactoryBot.create(:filter, role: role, permissions: [edit_permission])
        end
        let(:hosts) { FactoryBot.create_list(:host, 2, owner: user) }

        test 'should be authorized if setting allows owner' do
          Setting[:can_owner_modify_host_expiry_date] = true
          assert_equal true, authorizer.authorized?
        end

        test 'should not be authorized if setting does not allow owner' do
          Setting[:can_owner_modify_host_expiry_date] = false
          assert_equal false, authorizer.authorized?
        end
      end
    end

    context 'with unauthorized user' do
      let(:user) { FactoryBot.create(:user) }
      test 'should not be authorized' do
        assert_equal false, authorizer.authorized?
      end
    end
  end
end
