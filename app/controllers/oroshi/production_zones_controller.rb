module Oroshi
  class ProductionZonesController < ApplicationController
    before_action :set_production_zone

    # GET /oroshi/production_zones
    def index
      @production_zones = Oroshi::ProductionZone.all
    end

    # GET /oroshi/production_zones/1/edit
    def edit; end

    # GET /oroshi/production_zones/new
    def new
      @production_zone = Oroshi::ProductionZone.new
      @production_zone.active = true
    end

    # POST /oroshi/production_zones
    def create
      @production_zone = Oroshi::ProductionZone.new(production_zone_params)
      if @production_zone.save
        head :ok
      else
        render partial: 'production_zones_modal_form', status: :unprocessable_entity
      end
    end

    # PATCH/PUT /oroshi/production_zones/1
    def update
      if @production_zone.update(production_zone_params)
        head :ok if params[:autosave]
      else
        render 'edit', status: :unprocessable_entity
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_production_zone
      id = params[:id] || params[:production_zone_id]
      @production_zone = id ? Oroshi::ProductionZone.find(id) : Oroshi::ProductionZone.new
    end

    # Only allow a list of trusted parameters through.
    def production_zone_params
      params.require(:oroshi_production_zone)
            .permit(:name, :active)
    end
  end
end
