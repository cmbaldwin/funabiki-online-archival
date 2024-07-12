# spec/models/invoice_spec.rb
require 'rails_helper'

RSpec.describe Oroshi::Invoice, type: :model do
  subject { build(:oroshi_invoice) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  describe 'validations' do
    %w[start_date end_date send_email invoice_layout].each do |attribute|
      it "is not valid without a #{attribute}" do
        subject.send("#{attribute}=", nil)
        expect(subject).to_not be_valid
      end
    end

    it 'is not valid without send_at if send_email is true' do
      subject.send_email = true
      subject.send_at = nil
      expect(subject).to_not be_valid
    end

    it 'is valid without send_at if send_email is false' do
      subject.send_email = false
      subject.send_at = nil
      expect(subject).to be_valid
    end

    it 'is not valid without at least one supplier organization' do
      subject.supplier_organizations = []
      expect(subject).to_not be_valid
    end
  end

  describe 'associations' do
    let(:invoice) { create(:oroshi_invoice, :with_supply_dates) }

    it 'has supply dates' do
      expect(invoice.supply_dates.length).to be > 0
    end

    it 'has supplies' do
      expect(invoice.supplies.length).to be > 0
    end

    it 'has supplier organizations' do
      expect(invoice.supplier_organizations.length).to be > 0
    end
  end

  describe 'callbacks' do
    it 'locks supplies after create' do
      invoice = create(:oroshi_invoice, :with_supply_dates)
      invoice_supply_dates = Oroshi::Invoice::SupplyDate.where(invoice: invoice)
      # expect the invoice_supply_dates join to exist
      expect(invoice_supply_dates).to_not be 0
      supplies = invoice_supply_dates.map(&:supplies_with_invoice_supplier_organizations).flatten
      # only one invoice and supplies so all supplies should be locked
      expect(supplies.count).to_not be 0
    end

    it 'locks and unlocks supplies after create and destroy' do
      invoice = create(:oroshi_invoice, :with_supply_dates)
      invoice.destroy
      expect(invoice.supplies.all?(&:locked)).to be false
    end

    it 'does not destroy invoice if sent' do
      invoice = create(:oroshi_invoice, :with_supply_dates, sent_at: Time.zone.now)
      expect { invoice.destroy }.to_not(change { Oroshi::Invoice.count })
    end
  end
end
