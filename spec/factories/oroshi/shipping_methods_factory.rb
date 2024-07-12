FactoryBot.define do
  factory :oroshi_shipping_method, class: 'Oroshi::ShippingMethod' do
    transient do
      buyers do
        existing_buyers = Oroshi::Buyer.order('RANDOM()').limit(rand(1..3))
        existing_buyers.exists? ? existing_buyers : create_list(:oroshi_buyer, rand(1..3))
      end
    end
    name { FFaker::CompanyJA.name }
    sequence(:handle) { |n| "#{FFaker::Lorem.word}_#{n}" }
    departure_times { [9, 12, 15].sample(rand(1..3)) }
    daily_cost { rand(1.0..100.0).round(2) }
    per_shipping_receptacle_cost { rand(1.0..100.0).round(2) }
    per_freight_unit_cost { rand(1.0..100.0).round(2) }
    active { true }
    shipping_organization do
      Oroshi::ShippingOrganization.order('RANDOM()').limit(1).first ||
        create(:oroshi_shipping_organization)
    end

    after(:create) do |shipping_method, evaluator|
      shipping_method.buyers = evaluator.buyers
    end
  end
end
