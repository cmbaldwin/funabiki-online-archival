FactoryBot.define do
  factory :oroshi_packaging, class: 'Oroshi::Packaging' do
    name { FFaker::LoremJA.words(2).join }
    cost { rand(1.0..100.0).round(2) }
    active { true }

    after(:create) do |packaging|
      # Attach an image from a URL
      packaging.image.attach(
        io: URI.open('https://placehold.co/600x400'),
        filename: 'placeholder.png',
        content_type: 'image/png'
      )
    end

    trait :with_product_variations do
      after(:create) do |packaging|
        create_list(:oroshi_product_variation, rand(1..3), packagings: [packaging])
      end
    end
  end
end
