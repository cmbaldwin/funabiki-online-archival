require 'test_helper'

class AnalysisControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @office = users(:office)
    @unapproved = users(:unapproved)

    @admin.confirm
    @office.confirm

    sign_in @admin
  end

  test "should get index" do
    get analysis_url
    assert_response :success
  end

  test "should redirect non-admin user from check_status" do
    sign_out :user
    sign_in @office
    get analysis_url
    assert_redirected_to root_path
  end

  test "should not redirect admin user from check_status" do
    get analysis_url
    assert_response :success
  end
end
