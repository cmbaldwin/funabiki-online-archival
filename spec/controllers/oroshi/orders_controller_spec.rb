require 'rails_helper'

RSpec.describe Oroshi::OrdersController, type: :controller do
  let(:admin) { create(:user, :admin) }
  let(:oroshi_order) { create(:oroshi_order) }
  let(:oroshi_order_template) { create(:oroshi_order_template) }
  let(:today) { Time.zone.today }
  let(:oroshi_order_attributes) do
    attributes = attributes_for(:oroshi_order).dup
    # Convert shipping_date and arrival_date to their flatpickr JA style
    attributes[:shipping_date] = attributes[:shipping_date].strftime('%Y年%m月%d日')
    attributes[:arrival_date] = attributes[:arrival_date].strftime('%Y年%m月%d日')
    # Fix association IDs
    attributes[:buyer_id] = create(:oroshi_buyer).id
    product_variation = create(:oroshi_product_variation)
    attributes[:product_variation_id] = product_variation.id
    attributes[:shipping_receptacle_id] = product_variation.default_shipping_receptacle.id
    attributes[:shipping_method_id] = create(:oroshi_shipping_method).id
    attributes
  end

  before :each do
    sign_in admin
  end

  describe 'GET #index' do
    it 'redirects to index with date without order' do
      get :index
      # should redirect to the same index but with todays date
      expect(response).to redirect_to(oroshi_orders_path(today))
    end

    it 'shows index with date and no order' do
      get :index, params: { date: today }
      expect(response).to have_http_status(:success)
    end

    it 'returns http success with_order' do
      oroshi_order
      oroshi_order_template
      get :index, params: { date: today }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #show' do
    it 'returns http success' do
      oroshi_order
      oroshi_order_template
      get :show, params: { id: oroshi_order.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #edit' do
    it 'returns http success' do
      get :edit, params: { id: oroshi_order.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      before :each do
        oroshi_order
        oroshi_order_template
        oroshi_order_attributes
      end

      it 'creates a new Oroshi::Order' do
        expect do
          post :create, params: { oroshi_order: oroshi_order_attributes }
        end.to change(Oroshi::Order, :count).by(1)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new Oroshi::Order' do
        expect do
          oroshi_order_attributes[:shipping_date] = nil
          post :create, params: { oroshi_order: oroshi_order_attributes }
        end.to change(Oroshi::Order, :count).by(0)
      end

      it 'returns unprocessable_entity status and renders partial' do
        oroshi_order_attributes[:shipping_date] = nil
        post :create, params: { oroshi_order: oroshi_order_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      before :each do
        oroshi_order
        oroshi_order_template
        oroshi_order_attributes
      end

      it 'updates the requested oroshi_order' do
        new_date = Time.zone.tomorrow
        new_shipping_date = new_date.strftime('%Y年%m月%d日')
        patch :update, params: { id: oroshi_order.id,
                                 oroshi_order: {
                                   shipping_date: new_shipping_date,
                                   # simulate the flatpickr date format for both dates
                                   arrival_date: oroshi_order.arrival_date.strftime('%Y年%m月%d日')
                                 } }
        oroshi_order.reload
        expect(oroshi_order.shipping_date).to eq(new_date)
      end
    end
  end

  describe 'DELETE #destroy' do
    before :each do
      oroshi_order
      oroshi_order_template
    end

    it 'destroys the requested oroshi_order' do
      expect do
        delete :destroy, params: { id: oroshi_order.id }
      end.to change(Oroshi::Order, :count).by(-1)
    end
  end
end
