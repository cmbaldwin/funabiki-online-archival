require 'rails_helper'

RSpec.describe Oroshi::BuyersController, type: :controller do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  describe 'GET #index' do
    it 'returns http success' do
      create(:oroshi_buyer)
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #edit' do
    it 'returns http success' do
      buyer = create(:oroshi_buyer)
      get :edit, params: { id: buyer.id }
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
      buyer_attributes = attributes_for(:oroshi_buyer,
                                        shipping_methods: [create(:oroshi_shipping_method)])
      post :create, params: { oroshi_buyer: buyer_attributes }
    end

    it 'returns http unprocessable_entity with invalid params' do
      buyer_attributes = attributes_for(:oroshi_buyer, name: nil)
      post :create, params: { oroshi_buyer: buyer_attributes }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH #update' do
    it 'returns http success' do
      buyer = create(:oroshi_buyer)
      updated_attributes = attributes_for(:oroshi_buyer, name: 'Updated Name')
      patch :update, params: { id: buyer.id, oroshi_buyer: updated_attributes }
      expect(response).to have_http_status(:success)
    end
  end
end
