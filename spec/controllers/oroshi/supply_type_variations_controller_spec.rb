require 'rails_helper'

RSpec.describe Oroshi::SupplyTypeVariationsController, type: :controller do
  let(:admin) { create(:user, :admin) }

  before :each do
    sign_in admin
    create(:oroshi_supply_type)
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
      supply_type_variation_attributes = attributes_for(:oroshi_supply_type_variation)
      post :create, params: { oroshi_supply_type_variation: supply_type_variation_attributes }
    end

    it 'returns http unprocessable_entity with invalid params' do
      supply_type_variation_attributes = attributes_for(:oroshi_supply_type_variation, name: nil)
      post :create, params: { oroshi_supply_type_variation: supply_type_variation_attributes }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH #update' do
    it 'returns http success' do
      supply_type_variation = create(:oroshi_supply_type_variation)
      updated_attributes = attributes_for(:oroshi_supply_type_variation, name: 'Updated Supply Type Variation Name')
      patch :update, params: { id: supply_type_variation.id, oroshi_supply_type_variation: updated_attributes }
      expect(response).to have_http_status(:success)
    end
  end
end
