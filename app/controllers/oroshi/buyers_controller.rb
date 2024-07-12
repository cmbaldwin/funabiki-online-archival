module Oroshi
  class BuyersController < ApplicationController
    before_action :set_buyer, except: %i[index]
    before_action :set_buyers, only: %i[index]
    before_action :set_shipping_methods, except: %i[index]

    # GET /oroshi/buyers
    def index; end

    # GET /oroshi/buyers/1/edit
    def edit; end

    # GET /oroshi/buyers/new
    def new
      @buyer = Oroshi::Buyer.new
      @buyer.active = true
      2.times { @buyer.addresses.build }
    end

    # POST /oroshi/buyers
    def create
      @buyer = Oroshi::Buyer.new(buyer_params)
      if @buyer.save
        head :ok
      else
        render partial: 'buyer_modal_form', status: :unprocessable_entity
      end
    end

    # PATCH/PUT /oroshi/buyers/1
    def update
      if @buyer.update(buyer_params)
        head :ok if params[:autosave]
      else
        render 'edit', status: :unprocessable_entity
      end
    end

    def bundlable_orders
      date = Date.parse(params[:date])
      orders = @buyer.orders_with_date(date)
      render json: { orders: orders.map { |order| [order.id, order.to_s] } }
    end

    private

    def set_buyers
      @buyers = Oroshi::Buyer.order_by_associated_system_id
      @show_inactive = params[:show_inactive] == 'true'
      @buyers = @buyers.active unless @show_inactive
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_buyer
      id = params[:id] || params[:buyer_id]
      @buyer = id ? Oroshi::Buyer.find(id) : Oroshi::Buyer.active.first
    end

    def set_shipping_methods
      @shipping_methods = Oroshi::ShippingMethod.active
    end

    # Only allow a list of trusted parameters through.
    def buyer_params
      params[:oroshi_buyer][:active] = false if params[:oroshi_buyer][:active].to_i.zero?
      params.require(:oroshi_buyer)
            .permit(:name, :entity_type, :handle, :representative_phone, :fax, :associated_system_id,
                    :color, :handling_cost, :handling_cost_notes, :daily_cost, :daily_cost_notes,
                    :optional_cost, :optional_cost_notes, :commission_percentage, :brokerage, :active,
                    shipping_method_ids: [],
                    addresses_attributes: %i[id default active name company country_id subregion_id
                                             postal_code city address1 address2 phone])
    end
  end
end
