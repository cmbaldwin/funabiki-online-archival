require 'rails_helper'

RSpec.describe Oroshi::Buyer, type: :model do
  subject { build(:oroshi_buyer) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  describe 'validations' do
    %w[name handle handling_cost daily_cost entity_type optional_cost commission_percentage].each do |attribute|
      it "is not valid without a #{attribute}" do
        subject.send("#{attribute}=", nil)
        expect(subject).to_not be_valid
      end
    end

    it 'is not valid without a color' do
      subject.color = 'invalid'
      expect(subject).to_not be_valid
    end
  end

  describe 'associations' do
    let(:buyer) { create(:oroshi_buyer, :with_orders) }

    it 'has many addresses' do
      expect(buyer.addresses.length).to be > 0
    end

    it 'has many shipping methods' do
      expect(buyer.shipping_methods.length).to be > 0
    end

    it 'has many shipping organizations through shipping methods' do
      expect(buyer.shipping_organizations.length).to be > 0
    end

    it 'has many orders' do
      expect(buyer.orders.length).to be > 0
    end
  end
end
