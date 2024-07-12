require 'rails_helper'

RSpec.describe Oroshi::SupplyDate, type: :model do
  subject { build(:oroshi_supply_date) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  %w[date].each do |attribute|
    it "is not valid without a #{attribute}" do
      subject.send("#{attribute}=", nil)
      expect(subject).to_not be_valid
    end
  end

  # Association Assignments
  describe 'associations' do
    let(:supply_date) { create(:oroshi_supply_date, :with_supplies) }

    it 'has supplier organizations' do
      expect(supply_date.supplier_organizations.length).to be > 0
    end

    it 'has suppliers' do
      expect(supply_date.suppliers.length).to be > 0
    end

    it 'has supplies' do
      expect(supply_date.supplies.length).to be > 0
    end

    it 'has supply types' do
      expect(supply_date.supply_types.length).to be > 0
    end

    it 'has supply type variations' do
      expect(supply_date.supply_type_variations.length).to be > 0
    end
  end
end
