FactoryBot.define do
  factory :oroshi_order_template, class: Oroshi::OrderTemplate do
    association :order, factory: :oroshi_order

    notes { FFaker::LoremJA.sentence }
    identifier { FFaker::LoremJA.word }
  end
end
