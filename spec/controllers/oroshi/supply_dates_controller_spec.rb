require 'rails_helper'

RSpec.describe Oroshi::SupplyDatesController, type: :controller do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  describe 'GET #entry' do
    it 'returns http success' do
      supply_date = create(:oroshi_supply_date)
      supplier_organization = create(:oroshi_supplier_organization)
      supply_reception_time = create(:oroshi_supply_reception_time)
      get :entry, params: { date: supply_date.date,
                            supplier_organization_id: supplier_organization.id,
                            supply_reception_time_id: supply_reception_time.id }, format: :turbo_stream
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #checklist' do
    it 'returns http success' do
      get :checklist, params: { date: '2022-01-01', subregion_ids: ['1'], supply_reception_time_ids: ['1'] }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #supply_price_actions' do
    it 'returns http success' do
      get :supply_price_actions, as: :turbo_stream
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #supply_invoice_actions' do
    it 'returns http success' do
      supply_date = create(:oroshi_supply_date)
      get :supply_invoice_actions, params: { supply_dates: [supply_date.date] }, as: :turbo_stream
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #set_supply_prices' do
    include Oroshi::SuppliesHelper

    let(:supply_date) { create(:oroshi_supply_date, :with_supplies, zero_price: true) }
    let(:supply_dates) { [supply_date] }

    let(:set_supply_price_params) do
      {
        '[prices]' =>
        supply_date.supplier_organizations.each_with_object({}) do |supplier_organization, hash|
          suppliers = supplier_organization.suppliers.active
          variants = find_variants(supply_dates, suppliers)
          hash[supplier_organization.id] ||= {}
          supplier_organization.suppliers.count.times do |i|
            hash[supplier_organization.id][i] ||= {
              supplier_ids: [''],
              basket_prices: variants.each_with_object({}) { |variant, prices| prices[variant.id.to_s] = '' }
            }
            next if i > 1

            hash[supplier_organization.id][i] = {
              supplier_ids: supplier_organization.suppliers.active.pluck(:id).map(&:to_s),
              basket_prices: variants.each_with_object({}) do |supply_type_variation, prices|
                prices[supply_type_variation.id.to_s] = FFaker::Random.rand(1..1000).to_s
              end
            }
          end
        end,
        'supply_dates' => [supply_date.date.to_s]
      }
    end

    it 'returns http success and sets supply prices' do
      expect(supply_date.supply.count).to be > 0
      get :set_supply_prices, params: set_supply_price_params, as: :turbo_stream
      expect(response).to have_http_status(:success)
      expect(supply_date.incomplete_supply.count).to eq(0)
    end
  end
end
