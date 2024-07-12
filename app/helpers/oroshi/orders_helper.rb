module Oroshi::OrdersHelper
  # Order Dashboard Nav
  def order_nav_item(name, path, active, options = {})
    content_tag :li, class: 'nav-item', **options do
      link_to name, path, class: "nav-link #{'active' if active}",
                          data: { turbo_frame: 'orders_dashboard',
                                  action: 'oroshi--orders--order-dashboard#toggleActiveLink:passive' }
    end
  end

  # Order Form (modal)
  def filter_order_templates_button
    button_tag(
      icon('filter-circle').html_safe,
      class: 'btn btn-secondary',
      data: {
        controller: 'tippy', tippy_content: filter_order_templates_form, tippy_theme: 'light-border',
        tippy_trigger: 'click', tippy_interactive: 'true', tippy_placement: 'bottom-start', tippy_followCursor: 'false'
      }
    )
  end

  def filter_order_templates_form
    render 'oroshi/orders/dashboard/orders/filter_order_templates_form', orders: @orders
  end

  def buyer_select_options
    options = @buyers.map do |buyer|
      name = buyer.handle
      name += ' (発送方法はない)' if buyer.shipping_methods.empty?
      [name, buyer.id, buyer_option_attributes(buyer)]
    end
    options_for_select options, @order.buyer_id
  end

  def buyer_option_attributes(buyer)
    {
      data: {
        color: buyer.color,
        handling_cost: buyer.handling_cost,
        optional_cost: buyer.optional_cost
      }
    }.merge(buyer.shipping_methods.empty? ? { disabled: 'disabled' } : {})
  end

  def product_select_options
    options = @products.map do |product|
      no_variations = product.product_variations.empty?
      name = product.to_s
      name += ' (商品変種はない)' if no_variations
      option_attributes = no_variations ? { disabled: 'disabled' } : {}
      [name, product.id, option_attributes]
    end
    options_for_select options, @order.product_variation&.product&.id
  end

  def shipping_method_select_options
    options = @shipping_methods.map do |method|
      [method.name, method.id,
       { data: {
         oroshi__orders__order_form_target: 'shippingMethodOption',
         buyers: method.buyers.map(&:id).join(','),
         per_shipping_receptacle_cost: method.per_shipping_receptacle_cost,
         per_freight_cost: method.per_freight_unit_cost
       }, style: 'display: none;' }]
    end
    options_for_select options, @order.shipping_method_id
  end

  def product_variation_select_options
    options = @product_variations.flat_map do |product, variations|
      variations.map do |variation|
        ["#{variation.handle} (#{variation.name})", variation.id,
         { data: {
           product: product.id,
           default_shipping_receptacle: variation.default_shipping_receptacle_id,
           packaging_cost: variation.packaging_cost,
           default_self_life: variation.shelf_life,
           oroshi__orders__order_form_target: 'productVariationOption'
         }, style: 'display: none;' }]
      end
    end
    options_for_select options, @order.product_variation_id
  end

  def shipping_receptacle_select_options
    options = @shipping_receptacles.map do |receptacle|
      [receptacle.name, receptacle.id,
       { data: {
         cost: receptacle.cost,
         default_freight_bundle_quantity: receptacle.default_freight_bundle_quantity
       } }]
    end
    options_for_select options, @order.shipping_receptacle_id
  end

  # Orders list and entry by template entry form
  def combined_sorted_orders_and_templates(orders, templates, product_variation)
    product_variation_orders = orders ? orders[product_variation] || [] : []
    product_variation_templates = templates ? templates[product_variation] || [] : []
    combined_array = product_variation_orders + product_variation_templates
    combined_array.sort_by { |item| item.buyer.associated_system_id }
  end

  def render_order_or_template(item)
    if item.is_a?(Oroshi::Order)
      # Render order
      turbo_stream_from(item) +
        turbo_frame_tag(dom_id(item), class: 'w-100', src: edit_oroshi_order_path(item), loading: 'lazy') do
          render(partial: 'oroshi/shared/spinner')
        end
    else
      # Render template
      render('oroshi/orders/dashboard/orders/template', template: item)
    end
  end

  def order_number_field(form, field_name, args = {})
    form.number_field field_name,
                      class: 'order-number-field form-control form-control-sm align-middle text-center d-table-cell cursor-pointer',
                      style: "width: 3.5rem; min-width: 3.5rem; font-size: 0.75rem; #{if args[:readonly]
                                                                                        'background-color: #e0e0e0;'
                                                                                      end}",
                      data: {
                        oroshi__orders__order_target: 'quantityInput',
                        action: 'click->oroshi--orders--order#toggleQuantityInput change->oroshi--orders--order#updateQuantityInputs'
                      },
                      **args
  end

  def active_order_overlay
    content_tag :div,
                class: 'active-order-overlay position-absolute w-100 h-100 d-flex justify-content-center align-items-center cursor-pointer',
                data: {
                  controller: 'tippy',
                  tippy_content: 'クリックして注文を作成する',
                  oroshi__orders__order_target: 'activeOrderOverlay',
                  action: 'click->oroshi--orders--order#toggleOrderOverlay'
                } do
      ''
    end
  end

  def order_title(order = @order)
    content_tag :div,
                data: { controller: 'oroshi--orders--order-buyer-handle-ticker' },
                **order_title_class_style do
      buyer_color_and_handle(order.buyer).html_safe
    end
  end

  def order_title_modal_link(order = @order)
    link_to oroshi_order_show_path(order),
            **order_title_class_style,
            data: {
              action: 'click->oroshi--orders--order-dashboard#showModal:passive',
              controller: 'tippy oroshi--orders--order-buyer-handle-ticker',
              tippy_content: 'クリックして注文を表示・編集する'
            } do
      buyer_color_and_handle(order.buyer).html_safe
    end
  end

  def order_title_class_style
    { class: 'order-title-modal-link input-group-text p-1 text-nowrap
    d-flex gap-1 cursor-pointer overflow-hidden',
      style: 'max-width: 62px;' }
  end

  def buyer_color_and_handle(buyer)
    Rails.cache.fetch([buyer, buyer.color]) do
      content = ''.html_safe
      content << render('oroshi/shared/buyer_color_circle', color: buyer.color)
      content << content_tag(:div, class: 'ticker-container overflow-x-scroll') do
        content_tag(:div, buyer.handle,
                    data: { oroshi__orders__order_buyer_handle_ticker_target: 'buyerHandle' })
      end
      content.html_safe
    end
  end

  # Order price entry page
  def order_sales_title_modal_link
    link_to oroshi_order_show_path(@order),
            class: 'order-title-modal-link input-group-text p-1 text-nowrap d-flex gap-1 cursor-pointer mb-1',
            data: {
              action: 'click->oroshi--orders--order-dashboard#showModal:passive',
              controller: 'tippy',
              tippy_content: 'クリックして注文を表示・編集する'
            } do
      concat(@order.product_variation)
    end
  end

  # Order Production page
  def production_tab_link(text, production_view, active: false)
    link_to text, oroshi_orders_order_production_view_path(@date, production_view),
            id: "nav-#{production_view}-tab", class: "nav-link #{'active' if active}", role: 'tab', type: 'button',
            aria: { controls: "nav-#{production_view}", selected: active.to_s },
            data: { bs_toggle: 'tab', bs_target: "#nav-#{production_view}" }
  end

  def production_tab_pane(production_view, active: false)
    content_tag :div, class: "tab-pane fade #{'show active' if active}", id: "nav-#{production_view}",
                      role: 'tabpanel', aria: { labelledby: "nav-#{production_view}-tab" }, tabindex: '0' do
      turbo_frame_tag(production_view,
                      src: oroshi_orders_order_production_view_path(@date, production_view), loading: 'lazy') do
                        render partial: 'oroshi/shared/spinner'
                      end
    end
  end

  def calculate_counts_by_manufacture_and_expiration_date(product_variation, shipping_date)
    orders = @grouped_orders[[product_variation, shipping_date]] || []
    inventoried_orders = orders.group_by(&:product_inventory)
    accumulate_production_counts(product_variation, inventoried_orders)
    inventoried_orders.transform_values do |orders_with_manufacture_date|
      orders_with_manufacture_date.map(&:counts).transpose.map(&:sum)
    end
  end

  def accumulate_production_counts(product_variation, inventoried_orders)
    items = inventoried_orders.map { |inventory, orders| orders.sum(&:item_quantity) - inventory.quantity }.sum
    supply_name = product_variation.production_supply_name
    volume = items * product_variation.primary_content_volume
    @product_volume_totals[supply_name] = (@product_volume_totals[supply_name] || 0) + volume
    @volume_totals[supply_name] = (@volume_totals[supply_name] || 0) + volume
  end

  def display_relevant_inventories(relevant_inventories, sort_by)
    return '-' unless relevant_inventories&.any?

    relevant_inventories.map do |inventory|
      requests = inventory.production_requests
      request_string = requests.any? ? requests.sum(&:quantity) : '-'
      return request_string unless inventory.freight_quantity.positive?

      prefix = sort_by == 'shipping_date' ? inventory : inventory.to_short_s
      "#{prefix}: #{inventory.freight_quantity} (#{request_string})"
    end.uniq.join(' ').html_safe
  end
end
