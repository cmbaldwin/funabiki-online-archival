require 'rails_helper'

RSpec.describe Oroshi::SupplierOrganizationsController, type: :controller do
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

  describe 'GET #load' do
    it 'returns http success' do
      get :load
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
      supplier_organization_attributes = attributes_for(:oroshi_supplier_organization)
      post :create, params: { oroshi_supplier_organization: supplier_organization_attributes }
      expect(response).to have_http_status(:success)
    end

    it 'returns http unprocessable_entity with invalid params' do
      supplier_organization_attributes = attributes_for(:oroshi_supplier_organization, entity_name: nil)
      post :create, params: { oroshi_supplier_organization: supplier_organization_attributes }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH #update' do
    it 'returns http success' do
      supplier_organization = create(:oroshi_supplier_organization)
      updated_attributes = attributes_for(:oroshi_supplier_organization, name: 'Updated Name')
      patch :update, params: { id: supplier_organization.id, oroshi_supplier_organization: updated_attributes }
      expect(response).to have_http_status(:success)
    end
  end
end
