module Oroshi
  class ProductsController < ApplicationController
    before_action :set_products, only: %i[index load]
    before_action :set_product, only: %i[load edit update material_cost]

    # GET /oroshi/products
    def index; end

    # GET /oroshi/products/1/load
    def load
      render partial: 'oroshi/products/dashboard/settings'
    end

    # GET /oroshi/products/new
    def new
      @product = Oroshi::Product.new
      @product.active = true
    end

    # GET /oroshi/products/1/edit
    def edit; end

    # POST /oroshi/products
    def create
      @product = Oroshi::Product.new(product_params)
      if @product.save
        head :ok
      else
        render partial: 'products_modal_form', status: :unprocessable_entity
      end
    end

    # PATCH/PUT /oroshi/products/1
    def update
      if @product.update(product_params)
        head :ok if params[:autosave]
      else
        render 'edit', status: :unprocessable_entity
      end
    end

    # PATCH/PUT /oroshi/products/update_positions
    def update_positions
      new_positions = params[:new_positions]

      # Update logic goes here
      new_positions.each do |position_info|
        product = Oroshi::Product.find(position_info['product_id'])
        product.update(position: position_info['position'])
      end

      # Respond to the AJAX request
      respond_to do |format|
        format.json { render json: { message: 'Positions updated successfully' }, status: :ok }
      end
    rescue StandardError => e
      respond_to do |format|
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
    end

    # GET /oroshi/products/1/material_cost/:shipping_receptacle_id/:item_quantity/:receptacle_quantity/:freight_quantity
    def material_cost
      @shipping_receptacle = Oroshi::ShippingReceptacle.find(params[:shipping_receptacle_id])
      @quantity = params[:item_quantity].to_i
      @receptacle_quantity = params[:receptacle_quantity].to_i
      @freight_quantity = params[:freight_quantity].to_i
      @cost = @product.material_cost(@shipping_receptacle,
                                     item_quantity: @quantity,
                                     receptacle_quantity: @receptacle_quantity,
                                     freight_quantity: @freight_quantity)
      render json: { materials_cost: @cost }
    end

    private

    # Callbacks
    def set_product
      id = params[:id] || params[:product_id]
      @product = id ? Oroshi::Product.find(id) : @products.first
    end

    def set_products
      @products = Oroshi::Product.by_product_variation_count
      @show_inactive = params[:show_inactive] == 'true'
      @products = @products.active unless @show_inactive
    end

    # Only allow a list of trusted parameters through.
    def product_params
      params.require(:oroshi_product)
            .permit(:name, :units, :exterior_height, :exterior_width,
                    :exterior_depth, :active, :supply_type_id, :tax_rate,
                    :supply_loss_adjustment, :position, material_ids: [])
    end
  end
end
