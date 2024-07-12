FactoryBot.define do
  factory :oroshi_buyer, class: 'Oroshi::Buyer' do
    sequence(:name) { |n| "#{FFaker::CompanyJA.name}#{n}" }
    entity_type { Oroshi::Buyer.entity_types.keys.sample }
    sequence(:handle) { |n| "#{FFaker::Lorem.word}#{n}" }
    representative_phone { FFaker::PhoneNumberJA.phone_number }
    fax { FFaker::PhoneNumberJA.phone_number }
    associated_system_id { FFaker::LoremJA.word + FFaker::Number.number(digits: 3).to_s }
    color { "##{FFaker::Color.hex_code}" }
    handling_cost { rand(1.0..100.0).round(2) }
    handling_cost_notes { FFaker::LoremJA.sentence }
    daily_cost { rand(1.0..100.0).round(2) }
    daily_cost_notes { FFaker::LoremJA.sentence }
    optional_cost { rand(1.0..100.0).round(2) }
    optional_cost_notes { FFaker::LoremJA.sentence }
    commission_percentage { rand(0.0..25.0).round(2) }
    brokerage { [true, false].sample }
    active { true }
    addresses { build_list(:oroshi_address, 1) }
    shipping_methods do
      existing_shipping_methods = Oroshi::ShippingMethod.order('RANDOM()').limit(rand(1..3))
      if existing_shipping_methods.exists?
        existing_shipping_methods
      else
        shipping_organization = create(:oroshi_shipping_organization)
        create_list(:oroshi_shipping_method, rand(1..3), shipping_organization: shipping_organization)
      end
    end

    trait :with_orders do
      after(:create) do |buyer|
        buyer.orders << create_list(:oroshi_order, rand(1..3), buyer: buyer)
      end
    end
  end
end
