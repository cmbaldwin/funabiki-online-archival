require "application_system_test_case"

class OysterInvoicesTest < ApplicationSystemTestCase
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

  test 'can visit shikiri index from calendar button' do
    visit oyster_supplies_path
    sleep(1) # Wait to make sure the loading finishes
    find('.fc-shikiriList-button').click
    assert_selector 'h1', text: '牡蠣原料仕切り'
  end
end
