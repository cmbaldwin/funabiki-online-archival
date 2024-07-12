require 'application_system_test_case'
require 'oyster_supply_test_helper'
require 'sidekiq/testing'
Sidekiq::Testing.inline!

class OysterSuppliesTest < ApplicationSystemTestCase
  include OysterSupplyTestHelper

  setup do
    # Test creating and updating 5 randomized supplies
    setup_test_supplies
    @admin = users(:admin)
    @office = users(:office)
    @unapproved = users(:unapproved)

    @admin.confirm
    @office.confirm

    sign_in @admin
  end

  test 'visiting the index' do
    ensure_loaded('.fc-event')
    # Calendar loaded
    assert_selector 'h2.fc-toolbar-title', text: Time.zone.today.strftime('%Y年%-m月')
  end

  def ensure_loaded(element)
    visit oyster_supplies_path
    while all(element).count.zero?
      visit oyster_supplies_path
      sleep(1)
    end
  end

  test 'should show calendar with correct date' do
    visit oyster_supplies_path
    # Calendar loaded
    sleep(1) # Wait to make sure the loading finishes
    assert_selector '.fc-toolbar-title', text: Time.zone.today.strftime('%Y年%-m月')
  end

  test 'calendar can navigate back and fourth months and years' do
    ensure_loaded('.fc-event')
    # Calendar loaded
    assert_selector '.fc-toolbar-title', text: Time.zone.today.strftime('%Y年%-m月')
    # Click the next month button
    find('.fc-next-button').click
    # Ensure the month is correct
    assert_selector '.fc-toolbar-title', text: Time.zone.today.next_month.strftime('%Y年%-m月')
    # Click the previous month button
    find('.fc-prev-button').click
    # Ensure the month is correct
    assert_selector '.fc-toolbar-title', text: Time.zone.today.strftime('%Y年%-m月')
    # Click the next year button
    find('.fc-nextYear-button').click
    # Ensure the year is correct
    assert_selector '.fc-toolbar-title', text: Time.zone.today.next_year.strftime('%Y年%-m月')
    # Click the previous year button
    find('.fc-prevYear-button').click
    # Ensure the year is correct
    assert_selector '.fc-toolbar-title', text: Time.zone.today.strftime('%Y年%-m月')
  end

  test 'should popup create supply check' do
    @supply = OysterSupply.last
    visit oyster_supply_path(@supply.id)
    click_link(href: supply_check_path(@supply.id, receiving_times: %w[am pm]))
    sleep(0.3)
    assert_equal 1, Message.all.count
    Message.all.destroy_all # Clean up
  end

  test 'should show calendar buttons' do
    ensure_loaded('.supply_event') # Oyster Supplies loaded
    check_buttons
  end

  def check_buttons
    buttons = %w[shikiriNew tankaEntry analysis]
    buttons.each do |button|
      assert_selector ".fc-#{button}-button[disabled]"
    end
    # ensure three buttons with respective classes fc-shikiriNew-button fc-tankaEntry-button fc-analysis-button exist and are disabled
    select_calendar_dates
    buttons.each do |button|
      assert_selector ".fc-#{button}-button"
      assert_no_selector ".fc-#{button}-button[disabled]"
    end
  end

  test 'should create invoice and show invoice page' do
    assert_nothing_raised do
      ensure_loaded('.supply_event') # Oyster Supplies loaded
      select_calendar_dates
      find('.fc-shikiriNew-button').click
      find('#new_oyster_invoice .btn').click
      assert_selector '.message', text: '牡蠣原料仕切'
    end
  end

  test 'should modify price action modal' do
    assert_nothing_raised do
      ensure_loaded('.supply_event') # Oyster Supplies loaded
      select_calendar_dates
      find('.fc-tankaEntry-button').click
      find('#nav-hyogo')
      within all('[data-oyster-supplies--supply-price-actions-target="priceCard"]').first do
        all('option').first.click
        all('input').each do |input|
          input.set('100')
        end
      end
      find('#add-section').click
      find('#remove-section').click
      find('#nav-okayama-tab').click
      find('#_prices_okayama_hinase').set('100')
      find('#supply_action_partial input[type="submit"]').click
      sleep 1
      assert_selector '#supply_action_partial', text: '更新完成'
    end
  end

  def select_calendar_dates
    begin_selection = all('.fc-daygrid-day-number').first
    # target is fc-daygrid-day-number with end_string text
    end_selection = all('.fc-daygrid-day-number').last
    begin_selection.drag_to(end_selection)
  end

  test 'can edit supply' do
    ensure_loaded('.fc-event')
    assert_nothing_raised do
      today = Time.zone.today
      supply_string = today.strftime('%-d日')
      all('.fc-daygrid-day-number', text: supply_string).last.click
      sleep 1
      # Error with turbo drive with CORS, so just visit the page
      visit oyster_supply_path(OysterSupply.last.id)
      oyster_supply_id = find('.genryou')['data-id']
      # Sakoshi AM
      # Check that inputs change total values, indicating that js is set up correctly
      grand_total = find('#grand_total').text.to_i
      first_am_input = all('#nav-sakoshi-am input').first
      first_am_input.click
      input_value = first_am_input.value.to_i
      send_keys('0')
      send_keys(:tab)
      new_grand_total = find('#grand_total').text.to_i
      assert_equal grand_total - input_value, new_grand_total
      # Sakoshi PM, do the same
      find('[aria-controls="nav-sakoshi-pm"]').click
      grand_total = find('#grand_total').text.to_i
      first_pm_input = all('#nav-sakoshi-pm input[type="number"]').first
      first_pm_input.click
      input_value = first_pm_input.value.to_i
      send_keys('0')
      send_keys(:tab)
      new_grand_total = find('#grand_total').text.to_i
      assert_equal grand_total - input_value, new_grand_total
      # Aioi AM, do the same
      find('[aria-controls="nav-aioi-am"]').click
      grand_total = find('#grand_total').text.to_i
      first_am_input = all('#nav-aioi-am input[type="number"]').first
      first_am_input.click
      input_value = first_am_input.value.to_i
      send_keys('0')
      send_keys(:tab)
      new_grand_total = find('#grand_total').text.to_i
      assert_equal grand_total - input_value, new_grand_total
      # Aioi PM, do the same
      find('[aria-controls="nav-aioi-pm"]').click
      grand_total = find('#grand_total').text.to_i
      first_pm_input = all('#nav-aioi-pm input[type="number"]').first
      first_pm_input.click
      input_value = first_pm_input.value.to_i
      send_keys('0')
      send_keys(:tab)
      new_grand_total = find('#grand_total').text.to_i
      assert_equal grand_total - input_value, new_grand_total
      # Okayama
      find('[aria-controls="nav-okayama"]').click
      grand_total = find('#grand_total').text.to_i
      first_okayama_input = all('#nav-okayama input[type="number"]').first
      first_okayama_input.click
      input_value = first_okayama_input.value.to_i
      send_keys('0')
      send_keys(:tab)
      new_grand_total = find('#grand_total').text.to_i
      assert_equal grand_total - input_value, new_grand_total
      # Hoka
      find('[aria-controls="nav-hoka"]').click
      grand_total = find('#grand_total').text.to_i
      first_hoka_input = all('#nav-hoka input[type="number"]').first
      first_hoka_input.click
      input_value = first_hoka_input.value.to_i
      send_keys('0')
      send_keys(:tab)
      new_grand_total = find('#grand_total').text.to_i
      assert_equal grand_total - input_value, new_grand_total
      # Return up one level, to calendar index, and check that the new_grand_total
      # is included in the data for that supply record
      find('.bi-arrow-90deg-up').click
      sleep 1
      find(".tippy_#{oyster_supply_id}").text.include?(new_grand_total.to_s)
    end
  end
end
