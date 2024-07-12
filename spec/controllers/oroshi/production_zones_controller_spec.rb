require 'rails_helper'

RSpec.describe Oroshi::ProductionZonesController, type: :controller do
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
      production_zone_attributes = attributes_for(:oroshi_production_zone)
      post :create, params: { oroshi_production_zone: production_zone_attributes }
      expect(response).to have_http_status(:success)
    end

    it 'returns http unprocessable_entity with invalid params' do
      production_zone_attributes = attributes_for(:oroshi_production_zone, name: nil)
      post :create, params: { oroshi_production_zone: production_zone_attributes }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH #update' do
    it 'returns http success' do
      production_zone = create(:oroshi_production_zone)
      updated_attributes = attributes_for(:oroshi_production_zone, name: 'Updated Name')
      patch :update, params: { id: production_zone.id, oroshi_production_zone: updated_attributes }
      expect(response).to have_http_status(:success)
    end
  end
end
