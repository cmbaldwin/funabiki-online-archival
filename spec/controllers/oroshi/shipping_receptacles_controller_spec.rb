require 'rails_helper'

RSpec.describe Oroshi::ShippingReceptaclesController, type: :controller do
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

  describe 'GET #edit' do
    it 'returns http success' do
      shipping_receptacle = create(:oroshi_shipping_receptacle)
      get :edit, params: { id: shipping_receptacle.id }
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
      shipping_receptacle_attributes = attributes_for(:oroshi_shipping_receptacle)
      post :create, params: { oroshi_shipping_receptacle: shipping_receptacle_attributes }
    end

    it 'returns http unprocessable_entity with invalid params' do
      shipping_receptacle_attributes = attributes_for(:oroshi_shipping_receptacle, name: nil)
      post :create, params: { oroshi_shipping_receptacle: shipping_receptacle_attributes }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH #update' do
    it 'returns http success' do
      shipping_receptacle = create(:oroshi_shipping_receptacle)
      updated_attributes = attributes_for(:oroshi_shipping_receptacle, name: 'Updated Name')
      patch :update, params: { id: shipping_receptacle.id, oroshi_shipping_receptacle: updated_attributes }
      expect(response).to have_http_status(:success)
    end
  end
end
