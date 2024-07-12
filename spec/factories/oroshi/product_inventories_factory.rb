FactoryBot.define do
  factory :oroshi_product_inventory, class: 'Oroshi::ProductInventory' do
    quantity { rand(1..100) }

    association :product_variation, factory: :oroshi_product_variation
  end
end
