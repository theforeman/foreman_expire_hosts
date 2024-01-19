# frozen_string_literal: true

require 'test_plugin_helper'

class HostsHelperTest < ActionView::TestCase
  include HostsHelper
  include HostDescriptionHelper
  # Foreman 3.7 dropped this via
  # https://github.com/theforeman/foreman/commit/6cdb8c7a9ebd790537510213e43537a4a87189d6
  # Foreman 3.9 bought it back via
  # https://github.com/theforeman/foreman/commit/37a99c70ebd9e4d6f03af546dfe36e7678e2bcf3
  include PuppetRelatedHelper if defined?(PuppetRelatedHelper)
  include ForemanExpireHosts::HostsHelper
  include ApplicationHelper

  describe '#multiple_actions' do
    test 'includes expire bulk action' do
      assert_includes multiple_actions.map(&:first), 'Change Expiration'
    end
  end
end
