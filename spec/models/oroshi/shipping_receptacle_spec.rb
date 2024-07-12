require 'rails_helper'

RSpec.describe Oroshi::ShippingReceptacle, type: :model do
  subject { build(:oroshi_shipping_receptacle) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  describe 'validations' do
    %w[name handle cost default_freight_bundle_quantity active].each do |attribute|
      it "is not valid without a #{attribute}" do
        subject.send("#{attribute}=", nil)
        expect(subject).to_not be_valid
      end
    end
  end

  describe 'production request associations' do
    let(:shipping_receptacle) { create(:oroshi_shipping_receptacle, :with_production_requests) }

    it 'has many production_requests' do
      expect(shipping_receptacle.production_requests.count).to be > 0
    end
  end

  describe 'order associations' do
    let(:shipping_receptacle) { create(:oroshi_shipping_receptacle, :with_orders) }

    it 'has many orders' do
      expect(shipping_receptacle.orders.count).to be > 0
    end
  end
end
