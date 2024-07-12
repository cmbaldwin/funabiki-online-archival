module Oroshi
  class ShippingReceptaclesController < ApplicationController
    before_action :set_shipping_receptacle, only: %i[image edit update]

    # GET /oroshi/shipping_receptacles
    def index
      @shipping_receptacles = Oroshi::ShippingReceptacle.all
      @show_inactive = params[:show_inactive] == 'true'
      @shipping_receptacles = @shipping_receptacles.active unless @show_inactive
      @shipping_receptacles = @shipping_receptacles.order(:name, :handle, :cost)
    end

    # GET /oroshi/shipping_receptacles/1/image
    def image; end

    # GET /oroshi/shipping_receptacles/new
    def new
      @shipping_receptacle = Oroshi::ShippingReceptacle.new
      @shipping_receptacle.active = true
    end

    # POST /oroshi/shipping_receptacles
    def create
      @shipping_receptacle = Oroshi::ShippingReceptacle.new(shipping_receptacle_params)
      if @shipping_receptacle.save
        head :ok
      else
        render partial: 'shipping_receptacles_modal_form', status: :unprocessable_entity
      end
    end

    # GET /oroshi/shipping_receptacles/1/edit
    def edit; end

    # PATCH/PUT /oroshi/shipping_receptacles/1
    def update
      if @shipping_receptacle.update(shipping_receptacle_params)
        head :ok if params[:autosave]
      else
        render 'edit', status: :unprocessable_entity
      end
    end

    def estimate_per_box_quantity
      shipping_receptacle = Oroshi::ShippingReceptacle.find(params[:id])
      product_variation = Oroshi::ProductVariation.find(params[:product_variation_id])
      estimate_per_box_quantity = get_estimate_per_box_quantity(product_variation, shipping_receptacle)
      render json: { estimate_per_box_quantity: }
    end

    def get_estimate_per_box_quantity(product_variation, shipping_receptacle)
      default = product_variation.default_per_box
      return default if default&.positive?

      spacing_volume_adjustment = product_variation.spacing_volume_adjustment || 0.90
      shipping_receptacle.estimate_per_box_quantity(
        product_variation.product,
        adjustment: spacing_volume_adjustment
      )
    end

    private

    def set_shipping_receptacle
      @shipping_receptacle = Oroshi::ShippingReceptacle.find(params[:id])
    end

    def shipping_receptacle_params
      params.require(:oroshi_shipping_receptacle)
            .permit(:name, :handle, :cost, :default_freight_bundle_quantity,
                    :interior_height, :interior_width, :interior_depth,
                    :exterior_height, :exterior_width, :exterior_depth,
                    :active, :image)
    end
  end
end
