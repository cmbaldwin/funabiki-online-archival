require 'rails_helper'

RSpec.describe Oroshi::Product, type: :model do
  subject { build(:oroshi_product) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  describe 'validations' do
    %w[name units active].each do |attribute|
      it "is not valid without a #{attribute}" do
        subject.send("#{attribute}=", nil)
        expect(subject).to_not be_valid
      end
    end
  end
end
