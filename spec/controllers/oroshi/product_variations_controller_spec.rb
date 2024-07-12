require 'rails_helper'

RSpec.describe Oroshi::ProductVariationsController, type: :controller do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
    create(:oroshi_product)
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    it 'returns http success with valid params' do
      product_variation_attributes = attributes_for(:oroshi_product_variation)
      post :create, params: { oroshi_product_variation: product_variation_attributes }
    end

    it 'returns http unprocessable_entity with invalid params' do
      product_variation_attributes = attributes_for(:oroshi_product_variation, name: nil)
      post :create, params: { oroshi_product_variation: product_variation_attributes }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH #update' do
    it 'returns http success' do
      product_variation = create(:oroshi_product_variation)
      updated_attributes = attributes_for(:oroshi_product_variation, name: 'Updated Product Variation Name')
      patch :update, params: { id: product_variation.id, oroshi_product_variation: updated_attributes }
      expect(response).to have_http_status(:success)
    end
  end
end
