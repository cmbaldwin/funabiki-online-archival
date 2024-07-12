module ShippingListSettingPartials
  extend ActiveSupport::Concern

  def refresh_partials
    set_vars
    respond_to do |format|
      format.turbo_stream { render 'ec_products/refresh_partials' }
    end
  end

  def set_vars
    @ec_product_types = EcProductType.all
    @ec_products = EcProduct.all
    @ec_headers = settings('ec_headers')
    @restaurant_raw_headers = settings('restaurant_raw_headers')
    @restaurant_frozen_headers = settings('restaurant_frozen_headers')
    @settings = Setting.find_or_initialize_by(name: 'rakuten_processing_settings')
  end

  def settings(setting)
    Setting.find_by(name: setting)&.settings
  end

  def render_ec_product_tab(tab)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          tab,
          partial: partial_path(tab), locals: partial_locals(tab)
        )
      end
    end
  end

  def partial_path(tab)
    form_prefix = 'ec_products/forms/'
    preview_prefix = 'ec_products/previews/'
    case tab
    when 'ec_products_form', 'ec_product_types_form', 'rakuten_processing_settings'
      "#{form_prefix}#{tab}"
    when 'ec_shipping_list_preview', 'restaurant_shipping_list_preview'
      "#{preview_prefix}#{tab}"
    end
  end

  def partial_locals(tab)
    case tab
    when 'ec_products_form'
      { ec_products: EcProduct.all, ec_product_types: EcProductType.all }
    when 'ec_product_types_form'
      { ec_product_types: EcProductType.all }
    when 'rakuten_processing_settings'
      { settings: Setting.find_or_initialize_by(name: 'rakuten_processing_settings') }
    when 'ec_shipping_list_preview'
      { ec_products: EcProduct.all, ec_product_types: EcProductType.all, ec_headers: settings('ec_headers') }
    when 'restaurant_shipping_list_preview'
      { ec_products: EcProduct.all, ec_product_types: EcProductType.all,
        restaurant_raw_headers: settings('restaurant_raw_headers'),
        restaurant_frozen_headers: settings('restaurant_frozen_headers') }
    end
  end
end
