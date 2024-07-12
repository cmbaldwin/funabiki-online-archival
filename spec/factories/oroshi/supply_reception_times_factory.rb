FactoryBot.define do
  factory :oroshi_supply_reception_time, class: 'Oroshi::SupplyReceptionTime' do
    hour { FFaker::Number.between(from: 0, to: 23) }
    time_qualifier { %w[午前 午後 夜中 昼1 朝2 夜1].sample }
  end
end
