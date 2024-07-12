require "rails_helper"

RSpec.describe Oroshi::InvoiceMailer, type: :mailer do
  describe "invoice_notification" do
    let(:invoice) { create(:oroshi_invoice, :with_supply_dates) }
    let(:invoice_supplier_organization) { invoice.invoice_supplier_organizations.first }
    let(:mail) { Oroshi::InvoiceMailer.invoice_notification(invoice_supplier_organization.id) }

    it "renders the headers" do
      expect(mail.subject).to include(invoice_supplier_organization.supplier_organization.entity_name)
      expect(mail.to).to eq([invoice_supplier_organization.supplier_organization.email])
      expect(mail.from).to eq([Setting.find_by(name: 'oroshi_company_settings')&.settings&.dig('mail') || ENV.fetch('MAIL_SENDER', nil)])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(invoice_supplier_organization.supplier_organization.entity_name)
    end
  end
end
