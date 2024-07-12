FactoryBot.define do
  factory :oroshi_material_category, class: 'Oroshi::MaterialCategory' do
    name { FFaker::LoremJA.words(2).join }
    active { true }

    trait :with_materials do
      after(:create) do |material_cateogry|
        create_list(:oroshi_materials, 3, material_category: material_cateogry)
      end
    end
  end
end
