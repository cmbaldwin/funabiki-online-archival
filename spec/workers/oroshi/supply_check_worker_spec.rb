require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe Oroshi::SupplyCheckWorker, type: :worker do
  let(:supply_date) { create(:oroshi_supply_date, :with_supplies, zero_price: true) }
  let(:user) { create(:user, :admin) }
  let(:message) do
    create(:message,
           user: user.id.to_i,
           model: 'supply_check',
           message: "#{supply_date.date}供給受入れチェック表を作成中…",
           data: {
             supply_date: supply_date.date,
             filename: "供給受入チェック表 #{supply_date.date}.pdf",
             expiration: (DateTime.now + 1.day)
           })
  end

  let(:supplier_organization) { supply_date.supplier_organizations.first }
  let(:region_ids) { [supplier_organization.subregion_id] }
  let(:supply_reception_times) { [supplier_organization.supply_reception_times.first.id] }

  it 'should create and queue a worker' do
    expect do
      Oroshi::SupplyCheckWorker.perform_async(supply_date.date.to_s, message.id, region_ids, supply_reception_times)
    end.to change(Oroshi::SupplyCheckWorker.jobs, :size).by(1)
  end

  it 'should perform the worker' do
    Oroshi::SupplyCheckWorker.new.perform(supply_date.date.to_s, message.id, region_ids, supply_reception_times)
    message.reload
    expect(message.state).to be_truthy
    expect(message.message).to eq('牡蠣原料受入れチェック表作成完了。')
    expect(message.stored_file).to be_attached
  end
end
