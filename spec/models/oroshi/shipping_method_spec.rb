require 'rails_helper'

RSpec.describe Oroshi::ShippingMethod, type: :model do
  subject { build(:oroshi_shipping_method) }

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
    let(:shipping_method) { create(:oroshi_shipping_method, buyers:) }

    it 'has many buyers' do
      expect(shipping_method.buyers.length).to be > 0
    end
  end
end
