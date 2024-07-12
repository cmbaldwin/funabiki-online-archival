require 'rails_helper'

RSpec.describe Oroshi::MaterialsController, type: :controller do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  describe 'GET #index' do
    let(:material_category) { create(:oroshi_material_category) } # replace with your factory

    it "returns http success" do
      get :index, params: { material_category_id: material_category.id }
      expect(response).to have_http_status(:success)
    end

    it "renders the index template" do
      get :index, params: { material_category_id: material_category.id }
      expect(response).to render_template(:index)
    end
  end

  describe 'GET #edit' do
    it 'returns http success' do
      material = create(:oroshi_material)
      get :edit, params: { id: material.id }
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
      material_category = create(:oroshi_material_category)
      material_attributes = attributes_for(:oroshi_material,
                                           material_category_id: material_category.id)
      post :create, params: { oroshi_material: material_attributes }
    end

    it 'returns http unprocessable_entity with invalid params' do
      material_attributes = attributes_for(:oroshi_material, company_name: nil)
      post :create, params: { oroshi_material: material_attributes }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH #update' do
    it 'returns http success' do
      material = create(:oroshi_material)
      updated_attributes = attributes_for(:oroshi_material, company_name: 'Updated Name')
      patch :update, params: { id: material.id, oroshi_material: updated_attributes }
      expect(response).to have_http_status(:success)
    end
  end
end
