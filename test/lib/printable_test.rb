require 'test_helper'
require 'oyster_supply_test_helper'

class PrintableTest < ActiveSupport::TestCase
  include OysterSupplyTestHelper

  test "creates receipt pdf" do
    assert_nothing_raised do
      pdf_data = Receipt.new("sales_date" => "2021年01月01日", "order_id" => "1234567890", "purchaser" => "山田太郎", "title" => "様", "amount" => "1000", "expense_name" => "お品代として", "oysis" => "1", "tax_8_amount" => "100", "tax_8_tax" => "8", "tax_10_amount" => "100", "tax_10_tax" => "10")
      pdf = pdf_data.render
      assert pdf
    end
  end

  test "creates expiration card pdf" do
    assert_nothing_raised do
      card = ExpirationCard.new(product_name: "殻付き かき", manufacturer_address: "兵庫県赤穂市中広1576-11", manufacturer: "株式会社 船曳商店", ingredient_source: "兵庫県坂越海域", consumption_restrictions: "生食用", manufactuered_date: "2021年01月01日", expiration_date: "2021年01月05日", storage_recommendation: "要冷蔵　0℃～10℃", made_on: true, shomiorhi: true)
      card.save
      pdf_data = ShellCard.new(card.id)
      pdf = pdf_data.render
      assert pdf
    end
  end

  test "creates samurai oyster shipping list" do
    assert_nothing_raised do
      orders = FactoryBot.create_list(:funabiki_order, 5)
      # Make PDF
      pdf_data = OnlineShopPackingList.new(ship_date: Time.zone.today, included: %w[funabiki])
      pdf = pdf_data.render
      assert pdf
    end
  end

  test "creates rakuten packing list" do
    assert_nothing_raised do
      orders = FactoryBot.create_list(:rakuten_order, 5)
      # Make PDF
      pdf_data = OnlineShopPackingList.new(ship_date: Time.zone.today, included: %w[rakuten])
      pdf = pdf_data.render
      assert pdf
    end
  end

  test "creates oyster supply pdf" do
    setup_test_supplies

    assert_nothing_raised do
      # Make PDF
      pdf_data = OysterSupplyCheck.new(OysterSupply.last, receiving_times: %w[am pm])
      pdf = pdf_data.render
      assert pdf
    end
  end

  test "creates oyster supply invoice pdf" do
    setup_test_supplies

    assert_nothing_raised do
      # Make PDF (start_date, end_date, location: 'sakoshi', format: 'union', layout: '2024', password: nil, invoice_date: nil)
      pdf_data = Invoice.new(
        OysterSupply.last.date,
        OysterSupply.first.date + 1.day,
        location: 'sakoshi',
        format: 'union',
        layout: '2024',
        password: nil,
        invoice_date: Time.zone.today
      )
      pdf = pdf_data.render
      assert pdf
    end
  end
end
