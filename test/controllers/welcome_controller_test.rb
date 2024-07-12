require 'test_helper'

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @office = users(:office)
    @unapproved = users(:unapproved)

    @admin.confirm
    @office.confirm

    sign_in @admin
  end

  # Index loading Tests
  test 'should redirect unless logged in' do
    sign_out :user
    get root_url
    assert_redirected_to user_session_url
  end

  test 'should redirect if unconfirmed' do
    sign_out :user
    sign_in @unapproved

    get root_url
    assert_redirected_to user_session_url
  end

  test 'should get index as office user' do
    sign_out :user
    sign_in @office

    get root_url
    assert_response :success
  end

  test 'should get index as admin user' do
    get root_url
    assert_response :success
  end

lazy_render_partials = %w[rakuten_shinki_modal_url infomart_shinki_modal_url new_yahoo_orders_modal_url rakuten_orders_fp_url front_infomart_orders_url
                          yahoo_orders_partial_url funabiki_orders_partial_url receipt_partial_url daily_expiration_cards_url charts_partial_url printables_url]

lazy_render_partials.each do |partial|
    test "should get #{partial} as admin" do
      get send(partial)
      assert_response :success
    end

    test "should get #{partial} as office" do
      sign_out :user
      sign_in @office

      get send(partial)
      assert_response :success
    end
end
end
