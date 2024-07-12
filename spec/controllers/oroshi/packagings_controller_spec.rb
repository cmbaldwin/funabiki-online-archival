require 'rails_helper'

RSpec.describe Oroshi::PackagingsController, type: :controller do
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
      packaging = create(:oroshi_packaging)
      get :edit, params: { id: packaging.id }
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
      packaging_attributes = attributes_for(:oroshi_packaging)
      post :create, params: { oroshi_packaging: packaging_attributes }
    end

    it 'returns http unprocessable_entity with invalid params' do
      packaging_attributes = attributes_for(:oroshi_packaging, name: nil)
      post :create, params: { oroshi_packaging: packaging_attributes }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH #update' do
    it 'returns http success' do
      packaging = create(:oroshi_packaging)
      updated_attributes = attributes_for(:oroshi_packaging, name: 'Updated Name')
      patch :update, params: { id: packaging.id, oroshi_packaging: updated_attributes }
      expect(response).to have_http_status(:success)
    end
  end
end
