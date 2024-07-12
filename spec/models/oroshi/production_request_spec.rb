require 'rails_helper'

RSpec.describe Oroshi::ProductionRequest, type: :model do
  subject { build(:oroshi_production_request) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  describe 'validations' do
    %w[request_quantity fulfilled_quantity status].each do |attribute|
      it "is not valid without a #{attribute}" do
        subject.send("#{attribute}=", nil)
        expect(subject).to_not be_valid
      end
    end
  end

  describe 'associations' do
    let(:production_request) { create(:oroshi_production_request) }

    it 'belongs to a product variation' do
      expect(production_request.product_variation).to be_a(Oroshi::ProductVariation)
    end

    it 'has many supply type variations through product variation' do
      expect(production_request.supply_type_variations).to eq(production_request.product_variation.supply_type_variations)
    end

    it 'has one product inventory through product variation' do
      expect(production_request.product_inventory).to eq(production_request.product_variation.product_inventory)
    end

    it 'belongs to a production zone' do
      expect(production_request.production_zone).to be_a(Oroshi::ProductionZone)
    end

    it 'belongs to a shipping receptacle' do
      expect(production_request.shipping_receptacle).to be_a(Oroshi::ShippingReceptacle)
    end
  end
end
