# spec/models/supply_type_spec.rb
require 'rails_helper'

RSpec.describe Oroshi::SupplyTypeVariation, type: :model do
  subject { build(:oroshi_supply_type_variation) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  %w[supply_type_id name default_container_count active].each do |attribute|
    it "is not valid without a #{attribute}" do
      subject.send("#{attribute}=", nil)
      expect(subject).to_not be_valid
    end
  end

  # Association Assignments
  describe 'associations' do
    let(:supply_type_variation) { create(:oroshi_supply_type_variation) }

    it 'has supply_type' do
      expect(supply_type_variation.supply_type).to be_a(Oroshi::SupplyType)
    end
  end
end
