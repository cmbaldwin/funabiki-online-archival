require 'rails_helper'

RSpec.describe Oroshi::SupplierOrganization, type: :model do
  subject { build(:oroshi_supplier_organization) }

  # Validations
  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  %w[entity_type entity_name country_id subregion_id].each do |attribute|
    it "is not valid without a #{attribute}" do
      subject.send("#{attribute}=", nil)
      expect(subject).to_not be_valid
    end
  end

  # Association Assignments
  describe 'associations' do
    let(:supplier_organization) { create(:oroshi_supplier_organization, :with_suppliers) }

    it 'has suppliers' do
      expect(supplier_organization.suppliers.length).to be > 0
    end

    it 'has supply reception times' do
      expect(supplier_organization.supply_reception_times.length).to be > 0
    end

    it 'has addresses' do
      expect(supplier_organization.addresses.length).to be > 0
    end
  end
end
