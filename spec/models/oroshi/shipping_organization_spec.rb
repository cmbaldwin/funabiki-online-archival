require 'rails_helper'

RSpec.describe Oroshi::ShippingOrganization, type: :model do
  subject { build(:oroshi_shipping_organization) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  describe 'validations' do
    %w[name handle].each do |attribute|
      it "is not valid without a #{attribute}" do
        subject.send("#{attribute}=", nil)
        expect(subject).to_not be_valid
      end
    end
  end

  describe 'associations' do
    let(:buyers) { create_list(:oroshi_buyer, rand(1..3)) }
    let(:shipping_organization) { create(:oroshi_shipping_organization, buyers:) }

    it 'has many shipping methods' do
      expect(shipping_organization.shipping_methods.length).to be > 0
    end

    it 'has many buyers through shipping methods' do
      expect(shipping_organization.buyers.length).to be > 0
    end
  end
end
