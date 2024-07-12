module Oroshi
  class ProductInventoriesController < ApplicationController
    before_action :set_product_inventory, only: %i[show edit update destroy]

    def new
      @product_variation = ProductVariation.find(new_product_inventory_params[:product_variation])
      @product_inventory = @product_variation.product_inventories
                                             .find_or_initialize_by(
                                               manufacture_date: new_product_inventory_params[:manufacture_date],
                                               expiration_date: new_product_inventory_params[:expiration_date]
                                             )
      render :show
    end

    def create
      @product_inventory = ProductInventory.new(product_inventory_params)
      if @product_inventory.save
        render turbo_stream: [
          turbo_stream.replace('new_product_inventory', template: 'oroshi/product_inventories/edit')
        ]
      else
        render partial: 'new'
      end
    end

    def show
      @product_variation = @product_inventory.product_variation
    end

    def edit; end

    def update
      if @product_inventory.update(product_inventory_params)
        render :edit
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_product_inventory
      @product_inventory = ProductInventory.find(params[:id])
    end

    def product_inventory_params
      params.require(:oroshi_product_inventory).permit(:quantity, :manufacture_date, :expiration_date,
                                                       :product_variation_id)
    end

    def new_product_inventory_params
      params.permit(:product_variation, :manufacture_date, :expiration_date)
    end
  end
end
