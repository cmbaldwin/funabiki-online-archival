module Oroshi
  class ShippingMethodsController < ApplicationController
    before_action :set_shipping_method
    before_action :set_shipping_organization, only: %i[index new]
    before_action :set_shipping_organizations, only: %i[new update create]

    # GET /oroshi/shipping_methods
    def index
      @shipping_methods = @shipping_organization&.shipping_methods
      @show_inactive = params[:show_inactive] == 'true'
      @shipping_methods = @shipping_methods.active unless @show_inactive
    end

    # GET /oroshi/shipping_methods/1/edit
    def edit
      @shipping_organizations = Oroshi::ShippingOrganization.active
    end

    # GET /oroshi/shipping_methods/new
    def new
      @shipping_method.active = true
    end

    # POST /oroshi/shipping_methods
    def create
      @shipping_method = Oroshi::ShippingMethod.new(shipping_method_params)
      if @shipping_method.save
        head :ok
      else
        render partial: 'shipping_method_modal_form', status: :unprocessable_entity
      end
    end

    # PATCH/PUT /oroshi/shipping_methods/1
    def update
      if @shipping_method.update(shipping_method_params)
        head :ok if params[:autosave]
      else
        render 'edit', status: :unprocessable_entity
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_shipping_method
      id = params[:id] || params[:shipping_method_id]
      @shipping_method = id ? Oroshi::ShippingMethod.find(id) : Oroshi::ShippingMethod.new
    end

    def set_shipping_organization
      id = params[:shipping_organization_id]
      @shipping_organization = id ? Oroshi::ShippingOrganization.find(id) : Oroshi::ShippingOrganization.active.first
    end

    def set_shipping_organizations
      @shipping_organizations = Oroshi::ShippingOrganization.active
    end

    # Only allow a list of trusted parameters through.
    def shipping_method_params
      params.require(:oroshi_shipping_method)
            .permit(:name, :handle, :shipping_organization_id, :daily_cost,
                    :per_shipping_receptacle_cost, :per_freight_unit_cost,
                    :active, departure_times: [])
    end
  end
end
