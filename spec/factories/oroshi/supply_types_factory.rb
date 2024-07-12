FactoryBot.define do
  factory :oroshi_supply_type, class: 'Oroshi::SupplyType' do
    name { FFaker::LoremJA.words(2).join }
    units { %w[kg 個].sample }
    active { true }
    handle { FFaker::LoremJA.word }
    liquid { [true, false].sample }
  end
end
