module Oroshi
  class PackagingsController < ApplicationController
    before_action :set_packaging, only: %i[image edit update]
    before_action :set_packagings, only: %i[images]

    # GET /oroshi/packagings
    def index
      @packagings = Oroshi::Packaging.all.order(:name)
      @show_inactive = params[:show_inactive] == 'true'
      @packagings = @packagings.active unless @show_inactive
    end

    # GET /oroshi/packagings/1/image
    def image; end

    # GET /oroshi/packagings/1/images
    def images; end

    # GET /oroshi/packagings/new
    def new
      @packaging = Oroshi::Packaging.new
      @packaging.active = true
    end

    # POST /oroshi/packagings
    def create
      @packaging = Oroshi::Packaging.new(packaging_params)
      if @packaging.save
        head :ok
      else
        render partial: 'packagings_modal_form', status: :unprocessable_entity
      end
    end

    # GET /oroshi/packagings/1/edit
    def edit; end

    # PATCH/PUT /oroshi/packagings/1
    def update
      if @packaging.update(packaging_params)
        head :ok if params[:autosave]
      else
        ap @packaging.errors.full_messages
        render 'edit', status: :unprocessable_entity
      end
    end

    private

      def set_packaging
        @packaging = Oroshi::Packaging.find(params[:id])
      end

      def set_packagings
        @packagings = Oroshi::Packaging.find(params[:packaging_ids]) if params[:packaging_ids]
      end

      def packaging_params
        params.require(:oroshi_packaging)
              .permit(:name, :cost, :active, :image, :product_id)
      end
  end
end
