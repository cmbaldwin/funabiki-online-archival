FactoryBot.define do
  factory :oroshi_supply, class: 'Oroshi::Supply' do
    supplier { create(:oroshi_supplier) }
    supply_date { create(:oroshi_supply_date) }
    supply_reception_time do
      supplier.supplier_organization.supply_reception_times.sample
    end
    supply_type_variation do
      supplier.supply_type_variations.sample
    end
    locked { false }
    quantity { FFaker::Random.rand(1..100) }
    price { FFaker::Random.rand(1..1000) }
  end
end
