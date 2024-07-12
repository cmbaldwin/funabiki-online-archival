# spec/models/supply_type_spec.rb
require 'rails_helper'

RSpec.describe Oroshi::SupplyType, type: :model do
  subject { build(:oroshi_supply_type) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  %w[name handle units liquid active].each do |attribute|
    it "is not valid without a #{attribute}" do
      subject.send("#{attribute}=", nil)
      expect(subject).to_not be_valid
    end
  end

  # Association Assignments
  # Tested through variations
end
