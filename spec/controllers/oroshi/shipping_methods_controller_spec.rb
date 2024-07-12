require 'rails_helper'

RSpec.describe Oroshi::ShippingMethodsController, type: :controller do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  describe 'GET #index' do
    it 'returns http success' do
      create(:oroshi_shipping_organization)
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #edit' do
    it 'returns http success' do
      shipping_method = create(:oroshi_shipping_method)
      get :edit, params: { id: shipping_method.id }
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
      create(:oroshi_shipping_organization)
      shipping_method_attributes = attributes_for(:oroshi_shipping_method,
                                                  shipping_organization_id: Oroshi::ShippingOrganization.first.id)
      post :create, params: { oroshi_shipping_method: shipping_method_attributes }
    end

    it 'returns http unprocessable_entity with invalid params' do
      shipping_method_attributes = attributes_for(:oroshi_shipping_method, company_name: nil)
      post :create, params: { oroshi_shipping_method: shipping_method_attributes }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH #update' do
    it 'returns http success' do
      shipping_method = create(:oroshi_shipping_method)
      updated_attributes = attributes_for(:oroshi_shipping_method, company_name: 'Updated Company Name')
      patch :update, params: { id: shipping_method.id, oroshi_shipping_method: updated_attributes }
      expect(response).to have_http_status(:success)
    end
  end
end
