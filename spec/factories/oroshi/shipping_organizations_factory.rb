FactoryBot.define do
  factory :oroshi_shipping_organization, class: 'Oroshi::ShippingOrganization' do
    transient do
      buyers do
        Oroshi::Buyer.order('RANDOM()').limit(rand(1..3)) ||
          create_list(:oroshi_buyer, rand(1..3))
      end
    end

    name { FFaker::CompanyJA.name }
    sequence(:handle) { |n| "#{FFaker::Lorem.word}_#{n}" }
    active { true }
    addresses { build_list(:oroshi_address, 1) }

    after(:create) do |shipping_organization, evaluator|
      shipping_organization.shipping_methods << create_list(:oroshi_shipping_method, rand(1..3),
                                                            buyers: evaluator.buyers,
                                                            shipping_organization: shipping_organization)
    end
  end
end
