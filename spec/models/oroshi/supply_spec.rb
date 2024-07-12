# spec/models/supply_spec.rb
require 'rails_helper'

RSpec.describe Oroshi::Supply, type: :model do
  subject { build(:oroshi_supply) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  # Validation Tests
  describe 'validations' do
    %w[supply_date_id supplier_id supply_type_variation_id supply_reception_time_id].each do |attribute|
      it "is not valid without a #{attribute}" do
        subject.send("#{attribute}=", nil)
        expect(subject).to_not be_valid
      end
    end
  end

  # Association Assignments
  describe 'associations' do
    let(:supply) { create(:oroshi_supply) }

    it 'has supplier organization' do
      expect(supply.supplier_organization).to be_a(Oroshi::SupplierOrganization)
    end

    it 'has supplier' do
      expect(supply.supplier).to be_a(Oroshi::Supplier)
    end

    it 'has supply dates' do
      expect(supply.supply_date).to be_a(Oroshi::SupplyDate)
    end

    it 'has supply types' do
      expect(supply.supply_type).to be_a(Oroshi::SupplyType)
    end

    it 'has supply type variations' do
      expect(supply.supply_type_variation).to be_a(Oroshi::SupplyTypeVariation)
    end
  end

  describe 'after_save' do
    let(:supply_type) { create(:oroshi_supply_type) }
    let(:supply_type_variation) { create(:oroshi_supply_type_variation, supply_type: supply_type) }
    let(:supply_date) { create(:oroshi_supply_date) }
    let(:quantity) { 10 }

    it 'creates and updates supply_type and supply_type_variation joins when a supply is created' do
      expect do
        create(:oroshi_supply, supply_date: supply_date,
                               supply_type_variation: supply_type_variation,
                               quantity: quantity)
      end.to change { Oroshi::SupplyDate::SupplyType.count }
        .by(1)
        .and change { Oroshi::SupplyDate::SupplyTypeVariation.count }.by(1)

      supply_type_join = Oroshi::SupplyDate::SupplyType.find_by(supply_date: supply_date, supply_type: supply_type)
      expect(supply_type_join.total).to eq(quantity)

      supply_type_variation_join = Oroshi::SupplyDate::SupplyTypeVariation.find_by(supply_date: supply_date, supply_type_variation: supply_type_variation)
      expect(supply_type_variation_join.total).to eq(quantity)
    end
  end
end
