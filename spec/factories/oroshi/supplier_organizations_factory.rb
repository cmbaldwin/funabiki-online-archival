FactoryBot.define do
  factory :oroshi_supplier_organization, class: 'Oroshi::SupplierOrganization' do
    entity_type { Oroshi::SupplierOrganization.entity_types.keys.sample }
    entity_name { FFaker::CompanyJA.name }
    micro_region { FFaker::AddressJA.village }
    subregion_id { Carmen::Country.coded('392').subregions.sample.code.to_i }
    country_id { 392 } # Japan's ISO country code
    invoice_number { "T#{FFaker::Number.number(digits: 13)}" } # adjust as per your requirements
    invoice_name { FFaker::CompanyJA.name }
    honorific_title { "御中" }
    fax { FFaker::PhoneNumberJA.phone_number }
    email { FFaker::Internet.email }
    active { true }

    trait :with_suppliers do
      after(:create) do |supplier_organization|
        supplier_organization.suppliers << create_list(:oroshi_supplier, rand(1..3))
      end
    end

    after(:create) do |supplier_organization|
      supplier_organization.supply_reception_times << if Oroshi::SupplyReceptionTime.count < 4
        create_list(:oroshi_supply_reception_time, rand(1..3))
                                                      else
        Oroshi::SupplyReceptionTime.order('RANDOM()').limit(rand(1..3))
                                                      end
    end

    after(:create) do |supplier_organization|
      create(:oroshi_address, addressable: supplier_organization, default: true)
      create(:oroshi_address, addressable: supplier_organization)
    end
  end
end
