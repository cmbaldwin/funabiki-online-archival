require 'rails_helper'

RSpec.describe Oroshi::Packaging, type: :model do
  subject { build(:oroshi_packaging) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  describe 'validations' do
    %w[name cost active].each do |attribute|
      it "is not valid without a #{attribute}" do
        subject.send("#{attribute}=", nil)
        expect(subject).to_not be_valid
      end
    end
  end
end
