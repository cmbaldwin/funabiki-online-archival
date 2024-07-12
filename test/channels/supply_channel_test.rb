require "test_helper"
require 'oyster_supply_test_helper'

class SuppliesChannelTest < ActionCable::Channel::TestCase
  include OysterSupplyTestHelper
  fixtures :suppliers

  setup do
    setup_test_supplies
    @oyster_supply = OysterSupply.last
  end

  test "subscribes and broadcasts" do
    # requires a current_user
    stub_connection current_user: users(:admin)
    subscribe oyster_supply: @oyster_supply.id
    assert subscription.confirmed?

    # User connected broadcast
    ActionCable.server.broadcast("supplies_channel_#{@oyster_supply.id}", { type: 'USERS', users: [users(:admin).id] })
    assert_broadcast_on("supplies_channel_#{@oyster_supply.id}", { type: 'USERS', users: [users(:admin).id] })

    # Change input broadcast
    # this.subscription.send({
    #   type: 'INPUT_CHANGE', dig_point: digPoint, selector: selector, value: value
    # })
    supplier = Supplier.first
    original_value = @oyster_supply.oysters.dig('am', 'large', supplier.id.to_s, '1')
    dig_point = "[\"large\",\"#{supplier.id}\",\"1\"]"
    selector = "[name='oyster_supply[oysters][am[large][#{supplier.id}][1]]']"
    value = "100"
    perform :receive, { type: 'INPUT_CHANGE', dig_point: dig_point, selector: selector, value: value, session_id: '123' }
    # E.G: [ActionCable] Broadcasting to supplies_channel_5: {:type=>"INPUT_CHANGE", :user_id=>135138680, :selector=>"[name='oyster_supply[oysters][am[large][21578242][1]]']", :value=>"100"}
    assert_broadcast_on("supplies_channel_#{@oyster_supply.id}", { type: 'INPUT_CHANGE', user_id: users(:admin).id, session_id: '123', selector: selector, value: value })
  end
end
