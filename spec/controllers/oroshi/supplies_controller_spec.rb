require 'rails_helper'

RSpec.describe Oroshi::SuppliesController, type: :controller do
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

  describe 'PATCH #update' do
    it 'returns http success' do
      supply = create(:oroshi_supply)
      updated_attributes = attributes_for(:oroshi_supply, quantity: 10)
      patch :update, params: { id: supply.id, oroshi_supply: updated_attributes }
      expect(response).to have_http_status(:success)
    end
  end
end
