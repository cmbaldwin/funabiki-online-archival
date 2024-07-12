require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe Oroshi::InvoicePreviewWorker, type: :worker do
  let(:supply_dates) { create_list(:oroshi_supply_date, 2, :with_supplies) }
  let(:user) { create(:user, :admin) }
  let(:dates) { supply_dates.map(&:date).sort.map(&:to_s) }
  let(:supplier_organization) { supply_dates.first.supplier_organizations.first }

  %w[organization supplier].each do |invoice_format|
    %w[standard simple].each do |layout|
      context "when invoice_format is #{invoice_format} and layout is #{layout}" do
        let(:message) do
          create(:message,
                 user: user.id.to_i,
                 model: 'oroshi_invoice',
                 message: "供給仕切り書プレビュー作成中…",
                 data: {
                   invoice_id: 0,
                   invoice_preview: {
                     start_date: dates.first,
                     end_date: dates.last,
                     supplier_organization: supplier_organization.id,
                     invoice_format: invoice_format,
                     layout: layout
                   },
                   expiration: (DateTime.now + 1.day)
                 })
        end

        it 'should create and queue a worker' do
          expect do
            Oroshi::InvoicePreviewWorker
              .perform_async(dates.first, dates.last, supplier_organization.id, invoice_format, layout, message.id)
          end.to change(Oroshi::InvoicePreviewWorker.jobs, :size).by(1)
        end

        it 'should perform the worker' do
          Oroshi::InvoicePreviewWorker.new
                                      .perform(dates.first, dates.last, supplier_organization.id,
                                               invoice_format, layout, message.id)
          message.reload
          expect(message.state).to be_truthy
          expect(message.message).to eq('供給料仕切り書プレビュー作成完了')
          expect(message.stored_file).to be_attached
        end
      end
    end
  end
end
