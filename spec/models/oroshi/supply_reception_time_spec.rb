require 'rails_helper'

RSpec.describe Oroshi::SupplyReceptionTime, type: :model do
  subject { build(:oroshi_supply_reception_time) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  %w[hour time_qualifier].each do |attribute|
    it "is not valid without a #{attribute}" do
      subject.send("#{attribute}=", nil)
      expect(subject).to_not be_valid
    end
  end
end
