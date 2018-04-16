require 'test_plugin_helper'

module ForemanExpireHosts
  class SafeDestroyTest < ActiveSupport::TestCase
    class HostWithFailingCallbacks < ApplicationRecord
      self.table_name = 'hosts'
      self.inheritance_column = nil

      before_destroy :cancel

      private

      def cancel
        throw(:abort)
      end
    end

    describe 'model with failing callbacks' do
      test 'return false on record delete' do
        h = HostWithFailingCallbacks.create!(:name => 'test')
        assert_equal false, SafeDestroy.new(h).destroy!
        assert_equal 1, HostWithFailingCallbacks.all.count
      end
    end

    describe 'with a host' do
      let(:host) { FactoryBot.create(:host, :managed) }

      test 'deletes a host' do
        assert Host::Managed.find_by(id: host.id)
        assert SafeDestroy.new(host).destroy!
        refute Host::Managed.find_by(id: host.id)
      end
    end
  end
end
