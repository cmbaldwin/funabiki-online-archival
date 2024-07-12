module Oroshi
  class MaterialsController < ApplicationController
    before_action :set_material, only: %i[edit update]
    before_action :set_materials, only: %i[images]
    before_action :set_material_category, only: %i[index]

    # GET /oroshi/materials
    def index; end

    # GET /oroshi/materials/1/image
    def image; end

    # GET /oroshi/materials/1
    def images; end

    # GET /oroshi/materials/new
    def new
      @material = Oroshi::Material.new
      @material.active = true
    end

    # POST /oroshi/materials
    def create
      @material = Oroshi::Material.new(material_params)
      if @material.save
        head :ok
      else
        render partial: 'materials_modal_form', status: :unprocessable_entity
      end
    end

    # GET /oroshi/materials/1/edit
    def edit; end

    # PATCH/PUT /oroshi/materials/1
    def update
      if @material.update(material_params)
        head :ok if params[:autosave]
      else
        render 'edit', status: :unprocessable_entity
      end
    end

    private

    def set_material
      @material = Oroshi::Material.find(params[:id])
    end

    def set_materials
      @materials = Oroshi::Material.includes([:image_attachment]).find(params[:material_ids]) if params[:material_ids]
    end

    def set_material_category
      @material_category = Oroshi::MaterialCategory.find(params[:material_category_id])
      @materials = @material_category&.materials&.order(:name)
      @show_inactive = params[:show_inactive] == 'true'
      @materials = @materials.active unless @show_inactive
    end

    def material_params
      params.require(:oroshi_material)
            .permit(:name, :cost, :per, :material_category_id, :active, :image)
    end
  end
end
