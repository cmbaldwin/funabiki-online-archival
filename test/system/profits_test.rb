require 'application_system_test_case'
require 'oyster_supply_test_helper'

class ProfitsTest < ApplicationSystemTestCase
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

    @profit = profits(:one)
    @tokyo = markets(:tokyo)
    @tokyo_copy = markets(:tokyo_copy)
    @yoshi_mura = markets(:yoshi_mura)
  end

  test 'visiting the index' do
    # Index only test
    visit profits_path
    assert_selector 'h1', text: '計算表'
  end

  test 'creating a Profit' do
    visit profits_path
    sleep(0.5) # Loading
    # Calendar visiblity
    click_on 'newProfitModalButton'
    sleep(0.2) # Wait to make sure the animation finishes
    assert_text '新しい計算書の日付'
    # Create new, find a with text 13日 and click it
    find('a', text: '13日').click
    # First market view area should include full text of first market name
    assert_text @tokyo.namae
    # Another market's nickname should be visible on a button
    assert_text @yoshi_mura.nick
    sleep(0.5) # Loading
    # Click the button for a third market
    find("#navBtn#{@tokyo_copy.id}").click
    sleep(0.5) # Loading
    # Check market added to incomplete list
    first('.p_market_ordercount input').fill_in(with: '123')
    first('.p_market_ordercount input').native.send_keys(:return) # Press enter
    first('.p_market_unitcost input').fill_in(with: '123')
    find('body').click # Click anywhere to autosave
    first('.p_market_ordercount input').native.send_keys(:return) # Press enter
    # check moving around
    find("#navBtn#{@yoshi_mura.id}").click
    sleep(0.5) # Loading
    first('.p_market_ordercount input').fill_in(with: '123')
    first('.p_market_ordercount input').native.send_keys(:return) # Press enter
    sleep(0.5) # Loading
    # check to make sure #unfinished_list_partial now exists
    assert_selector '#unfinished_list_partial'
    sleep(0.5) # Loading
    # Check removed from completion list
    find("#navBtn#{@tokyo_copy.id}").click
    product = @tokyo_copy.products.first
    sleep(0.5) # Loading
    first('.p_market_ordercount input').fill_in(with: '123')
    first('.p_market_unitcost input').fill_in(with: '123')
    find('body').click # Click anywhere to autosave
    first('.p_market_unitcost input').native.send_keys(:return) # Press enter
    sleep(1) # Loading
    # submit the form
    find('.profit-submit').click
    sleep(1) # Loading
    # Add zeros in front of date, confirm it's in the right format
    within(find("#type_#{product.type} li#product_#{product.id}")) do
      # Enclosure characters removed for display
      assert_text product.namae.tr('()[]{}', '')
    end
    # Make sure the market is displaying
    markets = find("#type_#{product.type} li#product_#{product.id}").first('.market_name_col').text
    assert_includes markets, @tokyo_copy.nick
    # Make sure the total is positive (reflecting unit price input)
    subtotals = find('.subtotal_row', visible: false) # out of view
    scroll_to(subtotals)
    within(subtotals) do
      assert_not first('.col-4 h5').text.to_i.zero?
    end
    extras = find('#extra_costs', visible: false) # out of view
    scroll_to(extras)
    within(find('#extra_costs')) do
      assert_text @tokyo_copy.nick
      assert_text @tokyo_copy.one_time_cost.to_s
    end
    # Assure index throws no errors with new data
    visit profits_path
    sleep(0.5) # Loading
    assert_selector 'h1', text: '計算表'
    # Assure volumes modal loads
    first(:xpath, "//form[@data-tippy-content='牡蠣の量予算']").click
    volumes = find('#volumesModal')
    within(volumes) do
      assert_text '総合計'
    end
  end

  test 'updating a Profit' do
    visit profits_path
    sleep(0.5) # Loading
    first(:xpath, "//a[@data-tippy-content='編集する']").click
  end

  test 'destroying a Profit' do
    visit profits_path
    sleep(0.5) # Loading
    page.accept_confirm do
      first(:xpath, "//form[@data-tippy-content='削除する']").click
    end
  end
end
