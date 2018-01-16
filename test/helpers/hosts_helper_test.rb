require 'test_plugin_helper'

class HostsHelperTest < ActionView::TestCase
  include HostsHelper
  include ApplicationHelper

  describe '#multiple_actions' do
    test 'includes expire bulk action' do
      assert_includes multiple_actions.map(&:first), 'Change Expiration'
    end
  end
end
