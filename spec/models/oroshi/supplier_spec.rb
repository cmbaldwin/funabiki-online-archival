# spec/models/oroshi/supplier_spec.rb

require 'rails_helper'

RSpec.describe Oroshi::Supplier, type: :model do
  subject { build(:oroshi_supplier) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  %w[company_name supplier_number representatives invoice_number supplier_organization_id active].each do |attribute|
    it "is not valid without a #{attribute}" do
      subject.send("#{attribute}=", nil)
      expect(subject).to_not be_valid
    end
  end

  it "is not valid if active is not a boolean" do
    subject.active = nil
    expect(subject).to_not be_valid
  end

  describe "#circled_number" do
    it "returns the circled unicode character for the supplier_number" do
      subject.supplier_number = 5
      expect(subject.circled_number).to eq("⑤")
    end

    it "returns nil if the supplier_number is not between 1 and 20" do
      subject.supplier_number = 21
      expect(subject.circled_number).to be_nil
    end
  end

    # Association Assignments
    describe 'associations' do
      let(:supplier) { create(:oroshi_supplier) }

      it 'has supplier_organization' do
        expect(supplier.supplier_organization).to be_a(Oroshi::SupplierOrganization)
      end

      it 'has supply reception times' do
        expect(supplier.supply_reception_times.length).to be > 0
      end

      it 'has addresses' do
        expect(supplier.addresses.length).to be > 0
      end
    end
end
