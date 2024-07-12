require 'test_helper'
require 'oyster_supply_test_helper'

class OysterSuppliesControllerTest < ActionDispatch::IntegrationTest
  include OysterSupplyTestHelper

  setup do
    @admin = users(:admin)
    @office = users(:office)
    @unapproved = users(:unapproved)

    @admin.confirm
    @office.confirm

    sign_in @admin

    # Test creating and updating 5 randomized supplies
    setup_test_supplies
  end

  test 'should load index' do
    # Test with supplies
    get oyster_supplies_path
    assert_response :success

    # Test without
    OysterSupply.all.destroy_all
    get oyster_supplies_path
    assert_response :success
  end

  test 'should load new_by' do
    OysterSupply.find_by(supply_date: nengapi_date).destroy
    # Fullcalendar converts it's date to a rfc822 string parameter by default
    get new_by_url(Time.zone.today.to_formatted_s(:rfc822))
    assert_redirected_to oyster_supply_path(OysterSupply.last)
  end

  test 'should load show' do
    get oyster_supply_url(OysterSupply.first)
    assert_response :success
  end

  test 'should load edit' do
    get edit_oyster_supply_url(OysterSupply.first)
    assert_response :success
  end

  test 'should load oyster invice index' do
    get oyster_invoices_url
    assert_response :success
  end

  test 'should load oyster supply data calendar json' do
    # /oyster_supplies.json?place=supply_index
    get oyster_supplies_url(format: :json, place: 'supply_index')
    assert_response :success

    supply = OysterSupply.first
    string = DateTime.strptime(supply.supply_date, '%Y年%m月%d日')
    expected_title = supply_title(supply)

    json_response = JSON.parse(response.body)
    assert(json_response.any? { |item| item['title'] == expected_title }, "Expected to find title '#{expected_title}' in JSON response")
  end

  def supply_title(supply)
    total = supply.totals[:mukimi_total].round(0)
    est_price = supply.totals[:total_kilo_avg].round(0)
    "#{total}㎏　@#{est_price}¥/㎏"
  end

end
