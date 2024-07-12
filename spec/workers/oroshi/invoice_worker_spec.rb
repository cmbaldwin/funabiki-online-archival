require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe Oroshi::InvoiceWorker, type: :worker do
  let(:supply_dates) { create_list(:oroshi_supply_date, 2, :with_supplies) }
  let(:user) { create(:user, :admin) }
  let(:dates) { supply_dates.map(&:date).sort.map(&:to_s) }
  let(:supplier_organization) { supply_dates.first.supplier_organizations.first }

  %w[standard simple].each do |layout|
    context "when layout is #{layout}" do
      let(:invoice) do
        create(:oroshi_invoice, start_date: dates.first, end_date: dates.last,
                                invoice_layout: layout, supplier_organization_ids: [supplier_organization.id])
      end
      let(:message) do
        create(:message,
               user: user.id.to_i,
               model: 'oroshi_invoice',
               message: "供給仕切り書プレビュー作成中…",
               data: {
                 invoice_id: invoice.id,
                 expiration: (DateTime.now + 1.day)
               })
      end

      it 'should create and queue a worker' do
        expect do
          Oroshi::InvoiceWorker
            .perform_async(invoice.id, message.id)
        end.to change(Oroshi::InvoiceWorker.jobs, :size).by(1)
      end

      it 'should perform the worker' do
        Oroshi::InvoiceWorker.new
                             .perform(invoice.id, message.id)
        message.reload
        expect(message.state).to be_truthy
        expect(message.message).to eq('供給料仕切り書作成完了')
        # Each invoice organization join should have two invoices for organization whole and individual suppliers
        invoice.invoice_supplier_organizations.each do |join|
          expect(join.invoices.count).to eq(2)
        end
      end
    end
  end
end
