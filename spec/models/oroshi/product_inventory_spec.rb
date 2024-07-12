require 'rails_helper'

RSpec.describe Oroshi::ProductInventory, type: :model do
  subject { build(:oroshi_product_inventory) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  describe 'validations' do
    it "is not valid without a quantity" do
      subject.quantity = nil
      expect(subject).to_not be_valid
    end
  end

  describe 'is updated by product requests and orders' do
    let(:product_variation) { create(:oroshi_product_variation) }
    let(:production_request) do
      create(:oroshi_production_request,
             fulfilled_quantity: 0, product_variation: product_variation)
    end
    let(:buyer) { create(:oroshi_buyer) }
    let(:shipping_method) { buyer.shipping_methods.first }

    describe 'after update' do
      it 'updates the product inventory quantity' do
        # Test production requests
        production_request.update(status: :completed, fulfilled_quantity: 5)
        expect(product_variation.product_inventory.reload.quantity).to eq(5)
        production_request.update(status: :completed, fulfilled_quantity: 10)
        expect(product_variation.product_inventory.reload.quantity).to eq(10)
        # Test orders
        order = create(:oroshi_order, product_variation: product_variation, status: :confirmed,
                                      shipping_method: shipping_method, item_quantity: 5, buyer: buyer)
        order.update(status: :shipped)
        expect(product_variation.product_inventory.reload.quantity).to eq(5)
      end
    end
  end
end
