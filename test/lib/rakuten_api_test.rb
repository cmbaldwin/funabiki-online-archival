require 'test_helper'

class RakutenTest < ActiveSupport::TestCase
  test "fetches rakuten shinki" do
    assert_nothing_raised do
      Rakuten::Api.new.unprocessed_order_details
    end
  end

  test "refreshes rakuten api without error" do
    date = Date.today
    assert_nothing_raised do
      client = Rakuten::Api.new
      client.refresh(date: date, period: 1.day)
    end
  end
end
