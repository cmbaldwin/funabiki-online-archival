require 'ffaker'

FactoryBot.define do
  factory :message do
    user { create(:user, :admin).id.to_i }
    model { FFaker::Lorem.word }
    message { FFaker::Lorem.sentence }
    state { [true, false].sample }
    data { {} }
  end
end
