module Oroshi
  class MaterialCategoriesController < ApplicationController
    before_action :set_material_category, only: %i[edit update]

    # GET /oroshi/material_categorys
    def index
      @material_categories = Oroshi::MaterialCategory.all
      @show_inactive = params[:show_inactive] == 'true'
      @material_categories = @material_categories.active unless @show_inactive
    end

    # GET /oroshi/material_categorys/new
    def new
      @material_category = Oroshi::MaterialCategory.new
      @material_category.active = true
    end

    # POST /oroshi/material_categorys
    def create
      @material_category = Oroshi::MaterialCategory.new(material_category_params)
      if @material_category.save
        head :ok
      else
        render partial: 'material_categories_modal_form', status: :unprocessable_entity
      end
    end

    # GET /oroshi/material_categorys/1/edit
    def edit; end

    # PATCH/PUT /oroshi/material_categorys/1
    def update
      if @material_category.update(material_category_params)
        head :ok if params[:autosave]
      else
        render 'edit', status: :unprocessable_entity
      end
    end

    private

      def set_material_category
        @material_category = Oroshi::MaterialCategory.find(params[:id])
      end

      def material_category_params
        params.require(:oroshi_material_category).permit(:name, :active)
      end
  end
end
