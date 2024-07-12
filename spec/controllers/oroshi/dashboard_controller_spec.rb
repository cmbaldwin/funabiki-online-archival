require 'rails_helper'

RSpec.describe Oroshi::DashboardController, type: :controller do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #home' do
    it 'returns http success' do
      get :home
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #suppliers_organizations' do
    it 'returns http success' do
      get :suppliers_organizations
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #supply_types' do
    it 'returns http success' do
      get :supply_types
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #shipping' do
    it 'returns http success' do
      get :shipping
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #materials' do
    it 'returns http success' do
      get :materials
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #buyers' do
    it 'returns http success' do
      get :buyers
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #products' do
    it 'returns http success' do
      get :products
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #stats' do
    it 'returns http success' do
      get :stats
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #company' do
    it 'returns http success' do
      get :company
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #company_settings' do
    it 'returns http success' do
    params = {
      '[company_settings]': {
        name: 'Test Company',
        postal_code: '123-4567',
        address: 'Test Address',
        phone: '123-456-7890',
        fax: '123-456-7890',
        mail: 'test@company.com',
        web: 'www.test.com',
        invoice_number: 'T1234567890123'
      }
    }

    get :company_settings, params: params
      expect(response).to have_http_status(:success)
    end
  end
end
