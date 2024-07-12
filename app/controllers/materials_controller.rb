class MaterialsController < ApplicationController
  before_action :set_material, only: %i[show edit update destroy]
  before_action :check_status

  def check_status
    return unless !current_user.approved? || current_user.supplier? || current_user.user?

    flash[:notice] = 'そのページはアクセスできません。'
    redirect_to root_path, error: 'そのページはアクセスできません。'
  end

  # GET /materials
  # GET /materials.json
  def index
    @materials = Material.all
    @material = Material.new
  end

  # GET /materials/1
  # GET /materials/1.json
  def show
  end

  # GET /materials/new
  def new
    @material = Material.new
  end

  # GET /materials/1/edit
  def edit
  end

  # GET /insert_material/:id
  def insert_material
    params[:id] ? (@material = Material.find(params[:id])) : (@material = Material.new)

    render partial: 'material', locals: { material: @material }
  end

  # POST /materials
  # POST /materials.json
  def create
    @material = Material.new(material_params)
    @material.history = ({})

    respond_to do |format|
      if @material.save
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@material, partial: 'material', locals: { material: @material })
        end
        format.html { redirect_to @material, notice: '材料を作成されました。' }
        format.json { render :show, status: :created, location: @material }
      else
        format.html { render :new }
        format.json { render json: @material.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /materials/1
  # PATCH/PUT /materials/1.json
  def update
    current = []
    current << @material.namae.to_s
    current << @material.zairyou.to_s
    current << @material.cost.to_s
    @material.history[Time.now.to_s] = current

    respond_to do |format|
      if @material.update(material_params)
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@material, partial: 'material', locals: { material: @material })
        end
        format.html { redirect_to @material, notice: '材料を編集されました。' }
        format.json { render :show, status: :ok, location: @material }
      else
        format.html { render :edit }
        format.json { render json: @material.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /materials/1
  # DELETE /materials/1.json
  def destroy
    @material.destroy
    respond_to do |format|
      format.html { redirect_to materials_url, notice: '材料を削除されました。' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_material
    @material = Material.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def material_params
    params.require(:material).permit(:namae, :zairyou, :cost, :history, :divisor, :per_product, product_ids: [])
  end
end
