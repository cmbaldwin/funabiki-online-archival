require 'rails_helper'

RSpec.describe Oroshi::ProductVariation, type: :model do
  subject { build(:oroshi_product_variation) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  describe 'validations' do
    %w[name handle primary_content_volume primary_content_country_id primary_content_subregion_id active].each do |attribute|
      it "is not valid without a #{attribute}" do
        subject.send("#{attribute}=", nil)
        expect(subject).to_not be_valid
      end
    end
  end

  describe 'creates a product inventory' do
    it 'after creation' do
      expect { create(:oroshi_product_variation) }.to change(Oroshi::ProductInventory, :count).by(1)
    end
  end
end
