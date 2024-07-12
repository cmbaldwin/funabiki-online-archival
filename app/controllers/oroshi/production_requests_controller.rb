module Oroshi
  class ProductionRequestsController < ApplicationController
    before_action :set_conversion_vars, only: %i[convert]
    before_action :set_product_inventory_product_variation, only: %i[new create]
    before_action :set_production_request, only: %i[show edit update destroy]
    before_action :set_production_requests, only: %i[index]

    # GET /oroshi/production_requests/convert/:date(/:product_id)
    def convert
    end

    # GET /oroshi/product_inventories/:product_inventory_id/production_requests
    def index; end

    # GET /oroshi/product_inventories/:id
    def show
      set_product_inventory_product_variation_with_production_request
    end

    # GET /oroshi/product_inventories/new
    def new
      @production_request = Oroshi::ProductionRequest.new
      @production_request.product_inventory_id = @product_inventory.id if @product_inventory.persisted?
    end

    # POST /oroshi/product_inventories
    def create
      @product_inventory.save unless @product_inventory.persisted?
      @production_request = Oroshi::ProductionRequest.new(production_request_params)
      @production_request.product_inventory = @product_inventory
      if @production_request.save
        render turbo_stream: turbo_stream
          .replace('order_modal_content', template: 'oroshi/product_inventories/show')
      else
        # getting error
        render turbo_stream: turbo_stream
          .replace('new_production_request', template: 'oroshi/production_requests/new')
      end
    end

    # GET /oroshi/product_inventories/:id/edit
    def edit; end

    # PATCH/PUT /oroshi/product_inventories/:id
    def update
      if @production_request.update(production_request_params)
        set_product_inventory_product_variation_with_production_request
        render turbo_stream: [
          turbo_stream.replace(@production_request, partial: 'oroshi/production_requests/production_request',
                                                    locals: { production_request: @production_request }),
          turbo_stream.replace(@product_inventory, template: 'oroshi/product_inventories/edit')
        ]
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /oroshi/product_inventories/:id
    def destroy
      @production_request.destroy
      render turbo_stream: turbo_stream.remove(@production_request)
    end

    private

    # Params
    def production_request_params
      params.require(:oroshi_production_request).permit(:product_variation_id, :product_inventory_id,
                                                        :production_zone_id, :shipping_receptacle_id,
                                                        :request_quantity, :fulfilled_quantity, :status,
                                                        product_inventory_attributes:
                                                        %i[product_variation_id manufacture_date expiration_date])
    end

    def convert_params
      params.permit(:date, :product_id)
    end

    def set_conversion_vars
      @date = convert_params[:date]
      @product_id = convert_params[:product_id]
      @orders = if @product_id
                  Oroshi::Order.includes(:product_variation)
                               .where(oroshi_product_variations: { product_id: @product_id })
                               .includes(:product_inventory)
                else
                  Oroshi::Order.non_template.where(shipping_date: @date)
                               .includes(:product_inventory)
                end
      @product_inventories = @orders.map(&:product_inventory).uniq
    end

    def product_inventory_params
      production_request_params[:product_inventory_attributes]
    end

    # Set Product Inventory and Product Variation
    def set_product_inventory_product_variation
      @product_inventory = find_or_initialize_product_inventory
      @product_variation = @product_inventory.product_variation || find_product_variation
      @product_inventory.product_variation = @product_variation unless @product_inventory.product_variation
    end

    def find_or_initialize_product_inventory
      if production_request_params[:product_inventory_id].present?
        find_product_inventory_by_id
      else
        initialize_product_inventory
      end
    end

    def find_product_inventory_by_id
      Oroshi::ProductInventory.find(production_request_params[:product_inventory_id])
    end

    def initialize_product_inventory
      Oroshi::ProductInventory.find_or_initialize_by(
        product_variation_id: product_inventory_params[:product_variation_id],
        manufacture_date: product_inventory_params[:manufacture_date],
        expiration_date: product_inventory_params[:expiration_date]
      )
    end

    def find_product_variation
      Oroshi::ProductVariation.find(
        product_inventory_params[:product_variation_id] || production_request_params[:product_variation_id]
      )
    end

    # Production Request
    def set_production_request
      @production_request = Oroshi::ProductionRequest.find(params[:id])
    end

    def set_production_requests
      @product_inventory = Oroshi::ProductInventory.find(production_request_params[:product_inventory_id])
      @product_inventory.production_requests
    end

    def set_product_inventory_product_variation_with_production_request
      @product_inventory = @production_request.product_inventory
      @product_variation = @production_request.product_variation
    end
  end
end
