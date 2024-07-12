require 'rails_helper'

RSpec.describe Oroshi::SupplyReceptionTimesController, type: :controller do
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
      supply_reception_time_attributes = attributes_for(:oroshi_supply_reception_time)
      post :create, params: { oroshi_supply_reception_time: supply_reception_time_attributes }
      expect(response).to have_http_status(:success)
    end

    it 'returns http unprocessable_entity with invalid params' do
      supply_reception_time_attributes = attributes_for(:oroshi_supply_reception_time, hour: nil)
      post :create, params: { oroshi_supply_reception_time: supply_reception_time_attributes }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH #update' do
    it 'returns http success' do
      supply_reception_time = create(:oroshi_supply_reception_time)
      updated_attributes = attributes_for(:oroshi_supply_reception_time, hour: 10)
      patch :update, params: { id: supply_reception_time.id, oroshi_supply_reception_time: updated_attributes }
      expect(response).to have_http_status(:success)
    end
  end
end
