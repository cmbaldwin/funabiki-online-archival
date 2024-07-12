class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy index_product update_index_product insert_product_data create]
  before_action :check_status

  def check_status
    return unless !current_user.approved? || current_user.supplier? || current_user.user?
    flash[:notice] = 'そのページはアクセスできません。'
    redirect_to root_path, error: 'そのページはアクセスできません。'
  end

  # GET /products
  # GET /products.json
  def index
    helpers.types_hash
    @type = '1'
    @products = Product.order('namae').active
    @product = Product.new
  end

  def index_product
    render partial: 'products/index/product', locals: { product: @product }
  end

  # GET /products/1
  # GET /products/1.json
  def show
    render turbo_stream: turbo_stream.replace('product_form', partial: 'product', locals: { product: @product })
  end

  # GET /products/new
  def new
    @product = Product.new
    @product.profitable = true
    render turbo_stream: turbo_stream.replace('product_form', partial: 'product', locals: { product: @product })
  end

  # GET /products/1/edit
  def edit
    render turbo_stream: turbo_stream.replace("product_#{@product.id}", partial: 'products/index/edit_product', locals: { product: @product })
  end

  # POST /products
  # POST /products.json
  def create
    @product.type_check

    respond_to do |format|
      if @product.save
        format.html { redirect_to @product }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_index_product
    @product.update(product_params)
    render turbo_stream: turbo_stream.replace("product_#{@product.id}", partial: 'products/index/product', locals: { product: @product })
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    if params[:save_as]
      @product = Product.new(product_params)
      @product.type_check
      respond_to do |format|
        if @product.save
          format.html { redirect_to @product }
          format.json { render :show, status: :ok, location: @product }
        else
          format.html { render :edit }
          format.json { render json: @product.errors, status: :unprocessable_entity }
        end
      end
    else
      @product.type_check
      respond_to do |format|
        if @product.update(product_params)
          format.html { redirect_to @product }
          format.json { render :show, status: :ok, location: @product }
        else
          format.html { render :edit }
          format.json { render json: @product.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    @product.update(active: false)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@product) }
      format.json { head :no_content }
      format.html { redirect_to profits_url }
    end
  end

  def fetch_products_by_type
    helpers.types_hash
    @type = params[:type_id]

    render turbo_stream: turbo_stream.replace('products', partial: 'products/index/products', locals: { type: @type })
  end

  # POST /insert_product_data/:id
  def insert_product_data
    render turbo_stream: turbo_stream.replace('product_form', partial: 'product', locals: { product: @product })
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      id = params[:id] || params[:product_id]
      @product = id ? Product.find(id) : Product.new
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_params
      params.require(:product).permit(:namae, :profitable, :grams, :cost, :extra_expense, :product_type, :active, :associated, :count, :multiplier, material_ids: [], market_ids: [])
    end
end
