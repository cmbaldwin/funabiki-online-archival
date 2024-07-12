class EcProductTypesController < ApplicationController
  include ShippingListSettingPartials
  before_action :set_ec_product_type, only: %i[update destroy]

  def create
    @ec_product_type = EcProductType.new(ec_product_type_params)
    @ec_product_type.save
    render_ec_product_tab('ec_product_types_form')
  end

  def update
    @ec_product_type.update(ec_product_type_params)
    head :ok
  end

  def update_ec_product_types
    ec_product_types_params.each do |id, ec_product_type|
      EcProductType.find(id).update(ec_product_type)
    end
    new_product_type = EcProductType.new(ec_product_type_params)
    new_product_type.save unless new_product_type.errors.any?
    refresh_partials
  end

  def destroy
    @ec_product_type.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@ec_product_type) }
    end
  end

  private

  def ec_product_type_params
    params.require(:ec_product_type).permit(:name, :counter, :section, :restaurant_raw_section,
                                            :restaurant_frozen_section)
  end

  def ec_product_types_params
    params.require('ec_product_types').permit!
  end

  def set_ec_product_type
    @ec_product_type = EcProductType.find(params[:id])
  end
end
