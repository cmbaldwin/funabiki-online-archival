FactoryBot.define do
  factory :oroshi_supply_type_variation, class: 'Oroshi::SupplyTypeVariation' do
    name { FFaker::LoremJA.words(2).join }
    handle { FFaker::LoremJA.word }
    default_container_count { FFaker::Random.rand(1..5) } # adjust as per your requirements
    active { true }
    supply_type do
      if Oroshi::SupplyType.count.zero?
        create(:oroshi_supply_type)
      else
        Oroshi::SupplyType.order('RANDOM()').first
      end
    end

    trait :with_product_variations do
      after(:create) do |supply_type_variation|
        create_list(:oroshi_product_variation, rand(1..3), supply_type_variations: [supply_type_variation])
      end
    end
  end
end
