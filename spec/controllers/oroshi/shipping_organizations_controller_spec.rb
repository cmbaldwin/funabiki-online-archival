require 'rails_helper'

RSpec.describe Oroshi::ShippingOrganizationsController, type: :controller do
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
      shipping_organization_attributes = attributes_for(:oroshi_shipping_organization)
      post :create, params: { oroshi_shipping_organization: shipping_organization_attributes }
      expect(response).to have_http_status(:success)
    end

    it 'returns http unprocessable_entity with invalid params' do
      shipping_organization_attributes = attributes_for(:oroshi_shipping_organization, name: nil)
      post :create, params: { oroshi_shipping_organization: shipping_organization_attributes }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH #update' do
    it 'returns http success' do
      shipping_organization = create(:oroshi_shipping_organization)
      updated_attributes = attributes_for(:oroshi_shipping_organization, name: 'Updated Name')
      patch :update, params: { id: shipping_organization.id, oroshi_shipping_organization: updated_attributes }
      expect(response).to have_http_status(:success)
    end
  end
end
