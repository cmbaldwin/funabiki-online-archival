module Oroshi
  class ProductVariationsController < ApplicationController
    before_action :set_product, only: %i[index image new edit load]
    before_action :set_product_variations, only: %i[index load]
    before_action :set_product_variation, except: %i[create new]
    before_action :set_products, only: %i[new create edit load]
    before_action :set_associations, only: %i[new create edit load]

    # GET /oroshi/product_variations
    def index
      @show_inactive = params[:show_inactive] == 'true'
      @product_variations = @product_variations.active unless @show_inactive
    end

    # GET /oroshi/product_variations/1/load
    def load
      render @product_variation
    end

    # GET /oroshi/product_variations/1/image
    def image; end

    # GET /oroshi/product_variations/1/edit
    def edit; end

    # GET /oroshi/product_variations/new
    def new
      @product_variation = if params[:product_variation_id]
                             Oroshi::ProductVariation.find(params[:product_variation_id]).dup
                           else
                             Oroshi::ProductVariation.new(product_id: @product&.id, active: true)
                           end
    end

    # POST /oroshi/product_variations
    def create
      @product_variation = Oroshi::ProductVariation.new(product_variation_params)

      if @product_variation.save
        render turbo_stream: turbo_stream.replace('product_settings', partial: 'oroshi/products/dashboard/settings')
      else
        render partial: 'product_variations_modal_form', status: :unprocessable_entity
      end
    end

    # PATCH/PUT /oroshi/product_variations/1
    def update
      if @product_variation.update(product_variation_params)
        head :ok if params[:autosave]
      else
        render 'edit', status: :unprocessable_entity
      end
    end

    # GET /oroshi/product_variations/1/cost
    def cost
      cost_params
      render turbo_stream: turbo_stream.replace("product_variation_#{@product_variation.id}_costs", partial: 'cost')
    end

    private

    # Callbacks
    def set_associations
      @shipping_receptacles = Oroshi::ShippingReceptacle.active.order(:name, :handle, :cost)
      @shipping_receptacle = if @product_variation&.default_shipping_receptacle_id
                               Oroshi::ShippingReceptacle.find(@product_variation.default_shipping_receptacle_id)
                             else
                               @shipping_receptacles.first
                             end
      @packagings = @product_variation&.packagings || []
    end

    def set_product
      id = params[:product_id]
      @product = id ? Oroshi::Product.find(id) : Oroshi::Product.active.first
    end

    def set_product_variation
      id = params[:id] || params[:product_variation_id]
      @product_variation = if id
                             Oroshi::ProductVariation.find(id)
                           else
                             @product.product_variations.order(:name, :handle).first
                           end
    end

    def set_products
      @products = Oroshi::Product.active
    end

    def set_product_variations
      @product_variations = @product.product_variations.order(:name, :handle)
    end

    # Params
    def product_variation_params
      params.require(:oroshi_product_variation)
            .permit(:name, :handle, :primary_content_volume, :primary_content_country_id,
                    :primary_content_subregion_id, :shelf_life, :active, :product_id, :image,
                    :default_shipping_receptacle_id, :spacing_volume_adjustment, :default_per_box,
                    packaging_ids: [], production_zone_ids: [], supply_type_variation_ids: [])
    end

    # Cost json endpoint
    def cost_params
      set_shipping_receptacle
      set_quantity
      set_estimate
      set_cost_and_explanation
      set_shipping_receptacles
    end

    def set_shipping_receptacle
      @shipping_receptacle = if params[:shipping_receptacle_id]
                               Oroshi::ShippingReceptacle.find(params[:shipping_receptacle_id])
                             else
                               @product_variation.default_shipping_receptacle
                             end
    end

    def set_quantity
      @quantity = if params[:quantity]
                    params[:quantity].to_i
                  else
                    estimate_per_box_quantity
                  end
    end

    def estimate_per_box_quantity
      default = @product_variation.default_per_box
      return default if default&.positive?

      spacing_volume_adjustment = @product_variation.spacing_volume_adjustment || 0.90
      @shipping_receptacle.estimate_per_box_quantity(
        @product_variation.product,
        adjustment: spacing_volume_adjustment
      )
    end

    def set_estimate
      @estimate = @product_variation.production_cost_estimate(
        shipping_receptacle: @shipping_receptacle,
        quantity: @quantity
      )
    end

    def set_cost_and_explanation
      @cost = @estimate.first
      @explanation = @estimate.last
    end

    def set_shipping_receptacles
      @shipping_receptacles = Oroshi::ShippingReceptacle.active.order(:name, :handle, :cost)
    end
  end
end
