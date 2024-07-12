require 'test_helper'

class RakutenTest < ActiveSupport::TestCase
  test "fetches solidus shinki" do
    assert_nothing_raised do
      # Get orders
      client = SolidusAPI.new
      unfinished_orders = FunabikiOrder.unfinished.map(&:details)
      client.fetch_order_details(unfinished_orders)
      client.save_orders
      client.save('new_orders')
      client.save('processed_orders')
    end
  end
end
