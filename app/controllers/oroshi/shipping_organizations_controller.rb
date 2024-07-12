module Oroshi
  class ShippingOrganizationsController < ApplicationController
    before_action :set_shipping_organizations, only: %i[index load]
    before_action :set_shipping_organization, except: %i[new create]

    # GET /oroshi/shipping_organizations
    def index; end

    # GET /oroshi/shipping_organizations/1/load
    def load
      respond_to do |format|
        format.turbo_stream { render turbo_stream: 'load' }
        format.html { render partial: 'oroshi/shipping_organizations/dashboard/settings' }
      end
    end

    # GET /oroshi/shipping_organizations/new
    def new
      @shipping_organization = Oroshi::ShippingOrganization.new
      @shipping_organization.active = true
      2.times { @shipping_organization.addresses.build }
    end

    # POST /oroshi/shipping_organizations
    def create
      @shipping_organization = Oroshi::ShippingOrganization.new(shipping_organization_params)
      if @shipping_organization.save
        head :ok
      else
        render partial: 'shipping_organization_modal_form', status: :unprocessable_entity
      end
    end

    # PATCH/PUT /oroshi/shipping_organizations/1
    def update
      if @shipping_organization.update(shipping_organization_params)
        head :ok if params[:autosave]
      else
        render 'edit', status: :unprocessable_entity
      end
    end

    private

    def set_shipping_organizations
      @shipping_organizations = Oroshi::ShippingOrganization.all
      @show_inactive = params[:show_inactive] == 'true'
      @shipping_organizations = @shipping_organizations.active unless @show_inactive
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_shipping_organization
      id = params[:id] || params[:shipping_organization_id]
      @shipping_organization = id ? Oroshi::ShippingOrganization.find(id) : @shipping_organizations.first
    end

    # Only allow a list of trusted parameters through.
    def shipping_organization_params
      params[:oroshi_shipping_organization][:active] = false if params[:oroshi_shipping_organization][:active]
                                                                .to_i.zero?
      params.require(:oroshi_shipping_organization)
            .permit(:name, :handle, :active,
                    addresses_attributes: %i[id default active name company country_id phone
                                             subregion_id postal_code city address1 address2])
    end
  end
end
