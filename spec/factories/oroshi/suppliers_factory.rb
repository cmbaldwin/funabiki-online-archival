FactoryBot.define do
  factory :oroshi_supplier, class: 'Oroshi::Supplier' do
    company_name { FFaker::CompanyJA.name }
    short_name { FFaker::CompanyJA.name[0..5] } # assuming short_name is a shorter version of the company name
    supplier_number { FFaker::Random.rand(1..100) } # adjust as per your requirements
    user_id { FFaker::Random.rand(1..100) } # adjust as per your requirements
    representatives { Array.new(3) { FFaker::NameJA.name } } # creates an array of 3 random names
    invoice_number { FFaker::Random.rand(1..100).to_s } # adjust as per your requirements
    invoice_name { FFaker::CompanyJA.name }
    honorific_title { %W[\u5FA1\u4E2D \u69D8].sample }
    active { true }
    supplier_organization do
      if Oroshi::SupplierOrganization.count < 3
        create(:oroshi_supplier_organization)
      else
        Oroshi::SupplierOrganization.order('RANDOM()').first
      end
    end
    supply_type_variations do
      create(:oroshi_supply_type_variation) while Oroshi::SupplyTypeVariation.count < 12
      Oroshi::SupplyTypeVariation.order('RANDOM()').limit(rand(1..12)).to_a
    end

    after(:create) do |supplier|
      create(:oroshi_address, addressable: supplier, default: true)
      create(:oroshi_address, addressable: supplier)
    end
  end
end
