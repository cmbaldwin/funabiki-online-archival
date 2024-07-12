# spec/factories/users.rb
require 'ffaker'

FactoryBot.define do
  factory :user do
    username { FFaker::Internet.user_name }
    email { FFaker::Internet.email }
    password { Devise.friendly_token.first(8) }
    role { User.roles.keys.sample }
    approved { [true, false].sample }
    data { {} }

    trait :admin do
      role { :admin }
      admin { true }
      approved { true }
      after(:create) do |user|
        user.confirm
      end
    end
  end
end
