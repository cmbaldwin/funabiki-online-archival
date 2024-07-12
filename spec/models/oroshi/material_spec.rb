require 'rails_helper'

RSpec.describe Oroshi::Material, type: :model do
  subject { build(:oroshi_material) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  describe 'validations' do
    %w[name cost per active].each do |attribute|
      it "is not valid without a #{attribute}" do
        subject.send("#{attribute}=", nil)
        expect(subject).to_not be_valid
      end
    end
  end
end
