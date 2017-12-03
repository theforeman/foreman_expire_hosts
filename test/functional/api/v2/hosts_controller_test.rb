require 'test_plugin_helper'

class Api::V2::HostsControllerTest < ActionController::TestCase
  let(:host) do
    as_admin do
      FactoryBot.create(:host, :expires_in_a_year)
    end
  end

  test 'should show individual record with expiry data' do
    get :show, params: { :id => host.to_param }
    assert_response :success
    show_response = ActiveSupport::JSON.decode(@response.body)
    assert !show_response.empty?
    assert_equal host.expired_on, show_response['expired_on'].to_date
  end
end
