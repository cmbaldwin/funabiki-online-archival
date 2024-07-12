require 'rails_helper'

RSpec.describe Oroshi::Order, type: :model do
  subject { build(:oroshi_order) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  describe 'validations' do
    %w[item_quantity receptacle_quantity freight_quantity
       shipping_cost materials_cost sale_price_per_item].each do |attribute|
      it "is not valid without a #{attribute}" do
        subject.send("#{attribute}=", nil)
        expect(subject).to_not be_valid
      end
    end
  end

  describe 'associations' do
    let(:order) { create(:oroshi_order) }

    it 'belongs to a buyer' do
      expect(order.buyer).to be_a(Oroshi::Buyer)
    end

    it 'belongs to a product variation' do
      expect(order.product_variation).to be_a(Oroshi::ProductVariation)
    end

    it 'belongs to a shipping receptacle' do
      expect(order.shipping_receptacle).to be_a(Oroshi::ShippingReceptacle)
    end

    it 'belongs to a shipping method' do
      expect(order.shipping_method).to be_a(Oroshi::ShippingMethod)
    end
  end
end
