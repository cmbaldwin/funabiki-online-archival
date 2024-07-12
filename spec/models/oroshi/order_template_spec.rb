require 'rails_helper'

RSpec.describe Oroshi::OrderTemplate, type: :model do
  subject { build(:oroshi_order_template) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  describe 'validations' do
    it 'is not valid without an order' do
      subject.order = nil
      expect(subject).to_not be_valid
    end
  end

  describe 'associations' do
    let(:order_template) { create(:oroshi_order_template) }

    it 'belongs to an order' do
      expect(order_template.order).to be_a(Oroshi::Order)
    end
  end
end
