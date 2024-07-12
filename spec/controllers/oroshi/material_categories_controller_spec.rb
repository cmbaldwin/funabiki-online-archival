require 'rails_helper'

RSpec.describe Oroshi::MaterialCategoriesController, type: :controller do
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
      material_category = create(:oroshi_material_category)
      get :edit, params: { id: material_category.id }
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
      material_category_attributes = attributes_for(:oroshi_material_category)
      post :create, params: { oroshi_material_category: material_category_attributes }
    end

    it 'returns http unprocessable_entity with invalid params' do
      material_category_attributes = attributes_for(:oroshi_material_category, name: nil)
      post :create, params: { oroshi_material_category: material_category_attributes }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH #update' do
    it 'returns http success' do
      material_category = create(:oroshi_material_category)
      updated_attributes = attributes_for(:oroshi_material_category, name: 'Updated Name')
      patch :update, params: { id: material_category.id, oroshi_material_category: updated_attributes }
      expect(response).to have_http_status(:success)
    end
  end
end
