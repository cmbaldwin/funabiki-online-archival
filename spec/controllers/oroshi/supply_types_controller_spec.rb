require 'rails_helper'

RSpec.describe Oroshi::SupplyTypesController, type: :controller do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #load' do
    it 'returns a success response' do
      get :load
      expect(response).to be_successful
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
      supply_type_attributes = attributes_for(:oroshi_supply_type)
      post :create, params: { oroshi_supply_type: supply_type_attributes }
    end

    it 'returns http unprocessable_entity with invalid params' do
      supply_type_attributes = attributes_for(:oroshi_supply_type, name: nil)
      post :create, params: { oroshi_supply_type: supply_type_attributes }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH #update' do
    it 'returns http success' do
      supply_type = create(:oroshi_supply_type)
      updated_attributes = attributes_for(:oroshi_supply_type, name: 'Updated Supply Type Name')
      patch :update, params: { id: supply_type.id, oroshi_supply_type: updated_attributes }
      expect(response).to have_http_status(:success)
    end
  end
end
