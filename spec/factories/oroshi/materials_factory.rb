FactoryBot.define do
  factory :oroshi_material, class: 'Oroshi::Material' do
    name { FFaker::LoremJA.words(2).join }
    cost { rand(1.0..100.0).round(2) }
    per { Oroshi::Material.pers.keys.sample }
    active { true }
    material_category do
      if Oroshi::MaterialCategory.count < 3
        create(:oroshi_material_category)
      else
        Oroshi::MaterialCategory.order('RANDOM()').first
      end
    end

    after(:create) do |material|
      # Attach an image from a URL
      material.image.attach(
        io: URI.open('https://placehold.co/600x400'),
        filename: 'placeholder.png',
        content_type: 'image/png'
      )
    end

    trait :with_products do
      after(:create) do |material|
        create_list(:oroshi_product, 3, materials: [material])
      end
    end
  end
end
