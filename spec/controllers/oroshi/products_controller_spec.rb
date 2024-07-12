require 'rails_helper'

RSpec.describe Oroshi::ProductsController, type: :controller do
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

  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    it 'returns http success with valid params' do
      supply_type = create(:oroshi_supply_type)
      product_attributes = attributes_for(:oroshi_product, supply_type_id: supply_type.id)
      post :create, params: { oroshi_product: product_attributes }
      expect(response).to have_http_status(:success)
    end

    it 'returns http unprocessable_entity with invalid params' do
      product_attributes = attributes_for(:oroshi_product, name: nil)
      post :create, params: { oroshi_product: product_attributes }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH #update' do
    it 'returns http success' do
      product = create(:oroshi_product)
      updated_attributes = attributes_for(:oroshi_product, name: 'Updated Name')
      patch :update, params: { id: product.id, oroshi_product: updated_attributes }
      expect(response).to have_http_status(:success)
    end
  end
end
