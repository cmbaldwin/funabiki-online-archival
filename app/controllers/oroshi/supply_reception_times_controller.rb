module Oroshi
  class SupplyReceptionTimesController < ApplicationController
    before_action :set_supply_reception_time
    before_action :set_supplier_organization, only: %i[index create new]

    # GET /oroshi/supplies
    def index
      @supply_reception_times = Oroshi::SupplyReceptionTime.all
    end

    # GET /oroshi/supplies/1/edit
    def edit; end

    # GET /oroshi/supplies/new
    def new
      @supply_reception_time = Oroshi::SupplyReceptionTime.new
    end

    # POST /oroshi/supplies
    def create
      @supply_reception_time = Oroshi::SupplyReceptionTime.new(supply_reception_time_params)
      if @supply_reception_time.save
        head :ok
      else
        render partial: 'supply_reception_times_modal_form', status: :unprocessable_entity
      end
    end

    # PATCH/PUT /oroshi/supplies/1
    def update
      if @supply_reception_time.update(supply_reception_time_params)
        head :ok if params[:autosave]
      else
        render 'edit', status: :unprocessable_entity
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_supply_reception_time
      id = params[:id] || params[:supply_reception_time_id]
      @supply_reception_time = id ? Oroshi::SupplyReceptionTime.find(id) : Oroshi::SupplyReceptionTime.new
    end

    def set_supplier_organization
      id = params[:supplier_organization_id]
      @supplier_organization = id ? Oroshi::SupplierOrganization.find(id) : Oroshi::SupplierOrganization.first
    end

    # Only allow a list of trusted parameters through.
    def supply_reception_time_params
      params.require(:oroshi_supply_reception_time)
            .permit(:time_qualifier, :hour, supplier_organization_ids: [])
    end
  end
end
