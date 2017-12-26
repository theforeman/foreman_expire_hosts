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
  end
end
