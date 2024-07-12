module Oroshi
  class SupplyTypesController < ApplicationController
    before_action :set_supply_types, only: %i[index load]
    before_action :set_supply_type, except: %i[new create]

    # GET /oroshi/supplies
    def index; end

    # GET /oroshi/products/1/load
    def load
      render partial: 'oroshi/supply_types/dashboard/settings'
    end

    # GET /oroshi/supplies/new
    def new
      @supply_type = Oroshi::SupplyType.new
      @supply_type.active = true
    end

    # GET /oroshi/supplies/1/edit
    def edit; end

    # POST /oroshi/supplies
    def create
      @supply_type = Oroshi::SupplyType.new(supply_type_params)
      if @supply_type.save
        head :ok
      else
        render partial: 'supply_types_modal_form', status: :unprocessable_entity
      end
    end

    # PATCH/PUT /oroshi/supplies/1
    def update
      if @supply_type.update(supply_type_params)
        head :ok if params[:autosave]
      else
        render 'edit', status: :unprocessable_entity
      end
    end

    private

    def set_supply_types
      @supply_types = Oroshi::SupplyType.all
      @show_inactive = params[:show_inactive] == 'true'
      @supply_types = @supply_types.active unless @show_inactive
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_supply_type
      id = params[:id] || params[:supply_type_id]
      @supply_type = id ? Oroshi::SupplyType.find(id) : @supply_types.first
    end

    # Only allow a list of trusted parameters through.
    def supply_type_params
      params.require(:oroshi_supply_type)
            .permit(:name, :units, :active, :liquid, :handle)
    end
  end
end
