class EcProductsController < ApplicationController
  include ShippingListSettingPartials
  before_action :set_ec_product, only: %i[update destroy]
  before_action :set_vars, only: %i[index]

  def index; end

  def create
    @ec_product = EcProduct.new(ec_product_params)
    @ec_product.save
    render_ec_product_tab('ec_products_form')
  end

  def update
    @ec_product.update(ec_product_params)
    head :ok
  end

  def ec_product_tab
    render_ec_product_tab(params[:tab])
  end

  def update_ec_products
    ec_products_params.each do |id, ec_product|
      ec_product[:cross_reference_ids] = ec_product[:cross_reference_ids].split(',').map(&:strip)
      ec_product[:frozen_item] = nil if ec_product[:frozen_item].empty?
      EcProduct.find(id).update(ec_product)
    end
    new_product = EcProduct.new(ec_product_params)
    new_product.save unless new_product.errors.any?
    refresh_partials
  end

  def destroy
    @ec_product.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@ec_product) }
    end
  end

  def update_rakuten_processing_settings
    rakuten_processing_settings_params['ship_today_cutoff_hour'] = rakuten_processing_settings_params['ship_today_cutoff_hour'].to_i
    rakuten_processing_settings_params['automation_on'] = rakuten_processing_settings_params['automation_on'] == 'true'
    array_split_settings = ['ship_skip_products', 'ship_wait_products']
    array_split_settings.each do |setting|
      rakuten_processing_settings_params[setting] = rakuten_processing_settings_params[setting].split(',').map(&:strip)
    end
    rakuten_processing_settings_params['option_conversion_text'] = rakuten_processing_settings_params['option_conversion_text'].to_h.map { |_, inner_hash| inner_hash.values }
    Setting.find_or_create_by(name: 'rakuten_processing_settings').update(settings: rakuten_processing_settings_params)
    render_ec_product_tab('rakuten_processing_settings')
  end

  def ec_section_headers
    Setting.find_or_create_by(name: 'ec_headers')
           .update(settings: ec_section_headers_params)
    render json: { status: 'ok' }
  end

  def restaurant_raw_headers
    Setting.find_or_create_by(name: 'restaurant_raw_headers')
           .update(settings: restaurant_raw_headers_params)
    render json: { status: 'ok' }
  end

  def restaurant_frozen_headers
    Setting.find_or_create_by(name: 'restaurant_frozen_headers')
           .update(settings: restaurant_frozen_headers_params)
    render json: { status: 'ok' }
  end

  private

  def ec_section_headers_params
    params.require('/ec_section_headers').permit!
  end

  def restaurant_raw_headers_params
    params.require('/restaurant_raw_headers').permit!
  end

  def restaurant_frozen_headers_params
    params.require('/restaurant_frozen_headers').permit!
  end

  def fix_cross_reference_ids
    params[:ec_product][:cross_reference_ids] = params[:ec_product][:cross_reference_ids].split(',').map(&:strip)
  end

  def ec_product_params
    fix_cross_reference_ids
    params.require(:ec_product).permit(:name, :memo_name, :extra_shipping_cost, :frozen_item, :ec_product_type_id, :quantity, cross_reference_ids: [])
  end

  def ec_products_params
    params.require('ec_products').permit!
  end

  def rakuten_processing_settings_params
    params.require('rakuten_processing_settings').permit!
  end

  def set_ec_product
    @ec_product = EcProduct.find(params[:id])
  end
end
