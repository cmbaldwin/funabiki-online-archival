require 'rails_helper'

RSpec.describe Oroshi::SuppliersController, type: :controller do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  describe 'GET #index' do
    it 'returns http success' do
      create(:oroshi_supplier_organization)
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #edit' do
    it 'returns http success' do
      supplier = create(:oroshi_supplier)
      get :edit, params: { id: supplier.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    it 'returns http success with valid params' do
      create(:oroshi_supplier_organization)
      supplier_attributes = attributes_for(:oroshi_supplier,
                                           supplier_organization_id: Oroshi::SupplierOrganization.first.id)
      post :create, params: { oroshi_supplier: supplier_attributes }
    end

    it 'returns http unprocessable_entity with invalid params' do
      supplier_attributes = attributes_for(:oroshi_supplier, company_name: nil)
      post :create, params: { oroshi_supplier: supplier_attributes }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH #update' do
    it 'returns http success' do
      supplier = create(:oroshi_supplier)
      updated_attributes = attributes_for(:oroshi_supplier, company_name: 'Updated Company Name')
      patch :update, params: { id: supplier.id, oroshi_supplier: updated_attributes }
      expect(response).to have_http_status(:success)
    end
  end
end
