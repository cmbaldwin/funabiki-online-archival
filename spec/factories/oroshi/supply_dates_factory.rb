FactoryBot.define do
  factory :oroshi_supply_date, class: 'Oroshi::SupplyDate' do
    date do
      if Oroshi::SupplyDate.any?
        Oroshi::SupplyDate.last.date + 1.day
      else
        FFaker::Time.between(Time.zone.now.beginning_of_month, Time.zone.now.end_of_month)
      end
    end
    totals { {} }

    transient do
      zero_price { false }
    end

    trait :with_supplies do |evaluator|
      after(:create) do |oroshi_supply_date|
        10.times { create(:oroshi_supplier) } unless Oroshi::SupplierOrganization.any?
        Oroshi::SupplierOrganization.active.each do |supplier_organization|
          supplier_organization.supply_reception_times.each do |supply_reception_time|
            supplier_organization.suppliers.active.each do |supplier|
              supplier.supply_type_variations.each do |supply_type_variation|
                next unless supplier.supply_type_variations.include?(supply_type_variation)

                # Create 2 associated supplies for each supplier and supply_type_variation
                2.times do |t|
                  create(:oroshi_supply,
                         supply_date: oroshi_supply_date,
                         supplier: supplier,
                         supply_reception_time: supply_reception_time,
                         supply_type_variation: supply_type_variation,
                         quantity: t > 2 ? 0 : FFaker::Random.rand(1..100),
                         price: if evaluator.zero_price
                                  0
                                else
                                  t > 2 ? 0 : FFaker::Random.rand(1..1000)
                                end)
                end
              end
            end
          end
        end
      end
    end
  end
end
