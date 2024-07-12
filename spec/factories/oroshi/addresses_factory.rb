# Assuming you have defined factories for the models that will be used as addressable
FactoryBot.define do
  factory :oroshi_address, class: 'Oroshi::Address' do
    association :addressable, factory: :oroshi_supplier_organization
    name { FFaker::NameJA.name }
    company { FFaker::CompanyJA.name }
    address1 { FFaker::AddressJA.village + FFaker::AddressJA.land_number }
    address2 { FFaker::AddressJA.secondary_address }
    city { FFaker::AddressJA.city }
    postal_code { FFaker::AddressJA.postal_code }
    phone { FFaker::PhoneNumberJA.phone_number }
    alternative_phone { FFaker::PhoneNumberJA.phone_number }
    subregion_id { FFaker::Number.between(from: 1, to: 47) } # Japan has 47 prefectures
    country_id { "392" } # Japan's ISO country code
    default { false }
    active { true }
  end
end
