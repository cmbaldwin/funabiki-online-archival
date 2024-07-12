module Oroshi
  class OrdersController < ApplicationController
    before_action :set_order, only: %i[show edit update quantity_update price_update destroy]
    before_action :set_date, only: %i[index orders production production_view shipping sales revenue
                                      buyer_sales supply_volumes product_inventories new]
    before_action :set_orders, only: %i[orders shipping sales revenue]
    before_action :set_templates, only: %i[orders templates]
    before_action :set_revenue_vars, only: %i[revenue]
    before_action :set_order_buyers, only: %i[sales price_update]
    before_action :set_supply_volumes, only: %i[supply_volumes]
    before_action :set_product_inventories, only: %i[product_inventories]
    before_action :set_order_product_inventories, only: %i[production_view]
    before_action :set_input_vars, only: %i[show new edit create update]

    # GET /oroshi/orders/:date
    def index; end

    # POST /oroshi/orders/:date/form
    def orders
      handle_dashboard_response('orders') do
        set_filters
        @grouped_orders = @grouped_orders.group_by(&:product)
        @grouped_templates = @grouped_templates.group_by(&:product)
      end
    end

    # POST /oroshi/orders/:date/form
    def templates
      handle_dashboard_response('templates') do
        @grouped_templates = @order_templates.group_by { |template| template.order.product_variation.product }
      end
    end

    # GET /oroshi/orders/:date/production
    def production
      handle_dashboard_response('production')
    end

    # GET /oroshi/orders/:date/production_view/:production_view
    def production_view
      production_view = params[:production_view]
      render partial: "oroshi/orders/dashboard/production/#{production_view}"
    end

    # GET /oroshi/orders/:date/shipping
    def shipping
      handle_dashboard_response('shipping') do
        @grouped_orders = @orders.group_by(&:shipping_method)
        @products = Oroshi::Product.by_product_variation_count.includes(%i[product_variations supply_type])
      end
    end

    # GET /oroshi/orders/:date/sales
    def sales
      handle_dashboard_response('sales')
    end

    # GET /oroshi/orders/:date/revenue
    def revenue
      handle_dashboard_response('revenue')
    end

    def buyer_sales
      @buyer = Oroshi::Buyer.find(params[:buyer_id])
      @grouped_orders = @buyer.orders.where(shipping_date: @date).includes(:product_variation).group_by(&:product)
      render turbo_stream: [
        turbo_stream.replace('buyer_order_sales', partial: 'oroshi/orders/dashboard/sales/buyer_sales')
      ]
    end

    # GET /oroshi/orders/:date/supply_volumes
    def supply_volumes
      render turbo_stream: [
        turbo_stream.replace('supply_volumes', partial: 'oroshi/orders/dashboard/orders/supply_volumes')
      ]
    end

    # GET /oroshi/orders/:date/product_inventories
    def product_inventories
      render turbo_stream: [
        turbo_stream.replace('product_inventories', partial: 'oroshi/orders/dashboard/orders/product_inventories')
      ]
    end

    # GET /oroshi/orders/1
    def show
      show_order_modal
    end

    # GET /oroshi/orders/calendar
    def calendar
      render turbo_stream: [
        turbo_stream.replace('order_modal_content',
                             partial: 'oroshi/orders/modal/calendar')
      ]
    end

    def calendar_orders
      start_date = params[:start] ? Time.zone.parse(params[:start]) : Time.zone.today.beginning_of_month
      end_date = params[:end] ? Time.zone.parse(params[:end]) : Time.zone.today.end_of_month

      query_start = start_date - 7.days
      query_end = end_date + 7.days

      @orders_by_date = Oroshi::Order.non_template.where(shipping_date: query_start..query_end)
                                     .group(:shipping_date)
                                     .count

      @range = Date.parse(params[:start])..Date.parse(params[:end])
      @holidays = japanese_holiday_background_events(@range)

      render 'oroshi/orders/modal/calendar/orders'
    end

    # GET /oroshi/orders/new
    def new
      @order = Oroshi::Order.new
      show_order_modal
    end

    def new_order_from_template
      create_new_order_from_template
      if @order.save
        render_volume_and_inventory_updates(
          [turbo_stream.replace("oroshi_order_template_#{params[:template_id]}",
                                partial: 'oroshi/orders/order',
                                locals: { order: @order })]
        )
      else
        show_order_modal(status: :unprocessable_entity)
      end
    end

    # GET /oroshi/orders/1/edit
    def edit; end

    # POST /oroshi/orders
    def create
      @order = Oroshi::Order.new(order_params)
      if @order.save
        @date = @order.shipping_date
      else
        set_input_vars
        show_order_modal(status: :unprocessable_entity)
      end
    end

    # PATCH/PUT /oroshi/orders/1
    def update
      if order_params.delete(:copy_template) == '1' ? new_template_from_order : @order.update(order_params)
        render_volume_and_inventory_updates([turbo_stream
        .replace("oroshi_order_#{@order.id}",
                 partial: 'oroshi/orders/order',
                 locals: { order: @order })])
      else
        show_order_modal(status: :unprocessable_entity)
      end
    end

    def new_template_from_order
      order_template = @order.dup
      order_template.assign_attributes(order_params)
      order_template.is_order_template = true
      order_template.order_template = nil
      order_template.save
    end

    # PATCH/PUT /oroshi/orders/1/quantity_update
    def quantity_update
      # if any of the item_quantity, receptacle_quantity, or freight_quantity are 0, return json error with message
      return render json: { errors: ['数量は0にできません'] }, status: :unprocessable_entity if quantity_update_order_params
                                                                                       .values.map(&:to_i).any?(&:zero?)

      if @order.update(quantity_update_order_params)
        render_volume_and_inventory_updates
      else
        render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /oroshi/orders/1/price_update
    def price_update
      if @order.update(price_update_order_params)
        @orders = Oroshi::Order.non_template.where(shipping_date: @date).includes(:buyer)
        render turbo_stream: [
          turbo_stream.replace("order_sales_form_#{@order.id}",
                               partial: 'oroshi/orders/dashboard/sales/order_sales_form',
                               locals: { order: @order }),
          turbo_stream.replace('buyer_sales_nav',
                               partial: 'oroshi/orders/dashboard/sales/buyer_sales_nav',
                               locals: { active_buyer: @order.buyer })
        ]
      else
        render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /oroshi/orders/1
    def destroy
      date = @order.shipping_date
      @order.destroy
      redirect_to oroshi_orders_path(date: date.to_s)
    end

    # DELETE /oroshi/orders/template/template_id
    def destroy_template
      order_template = Oroshi::OrderTemplate.find(params[:template_id])
      order_template.destroy
      render turbo_stream: [
        turbo_stream.remove("oroshi_order_template_#{params[:template_id]}")
      ]
    end

    private

    def show_order_modal(options = {})
      render turbo_stream: [
        turbo_stream.replace('order_modal_content', partial: 'order_modal_form')
      ], **options
    end

    def render_volume_and_inventory_updates(additional_streams = [])
      @date = @order.shipping_date
      set_orders
      set_supply_volumes
      set_product_inventories
      render turbo_stream: [
        turbo_stream.replace('product_inventories', partial: 'oroshi/orders/dashboard/orders/product_inventories'),
        turbo_stream.replace('supply_volumes', partial: 'oroshi/orders/dashboard/orders/supply_volumes'),
        *additional_streams
      ]
    end

    def set_date
      return redirect_to oroshi_orders_path(date: Time.zone.today.to_s) if params[:date].blank?

      @date = Date.parse(params[:date])
    end

    def set_order
      @order = Oroshi::Order.find(params[:id] || params[:order_id])
      @order.is_order_template = @order.order_template.present?
    end

    def set_orders
      @orders = Oroshi::Order.non_template.where(shipping_date: @date)
                             .includes(:buyer, :product,
                                       shipping_method: %i[buyers shipping_organization],
                                       product_variation: %i[supply_type_variations product])
    end

    def set_templates
      @order_templates = Oroshi::OrderTemplate.all.includes(order: %i[buyer product_variation shipping_receptacle])
      # get a list of all buyer and product variation combinations in @orders
      # remove any combinations that have an order template with the same
      # buyer product variation, and shipping receptacle in the order template's associated orders
      @order_templates = @order_templates.reject do |order_template|
        @orders&.any? do |order|
          order.buyer_id == order_template.buyer.id &&
            order.product_variation_id == order_template.product_variation.id &&
            order.shipping_receptacle_id == order_template.shipping_receptacle.id
        end
      end
    end

    def set_filters
      @grouped_orders = @orders
      @grouped_templates = @order_templates
      @buyer_ids = params[:buyer_ids]&.reject(&:blank?)
      @shipping_method_ids = params[:shipping_method_ids]&.reject(&:blank?)
      return unless @buyer_ids.present? || @shipping_method_ids.present?

      @grouped_orders = @grouped_orders.where(buyer_id: @buyer_ids) if @buyer_ids.present?
      @grouped_orders = @grouped_orders.where(shipping_method_id: @shipping_method_ids) if @shipping_method_ids.present?

      if @buyer_ids.present?
        @grouped_templates = @grouped_templates.select do |order_template|
          @buyer_ids.include?(order_template.buyer.id.to_s)
        end
      end

      return unless @shipping_method_ids.present?

      @grouped_templates = @grouped_templates.select do |order_template|
        @shipping_method_ids.include?(order_template.shipping_method.id.to_s)
      end
    end

    def set_revenue_vars
      @grouped_orders = @orders.group_by { |order| order.product_variation.product }
      @buyers = @orders.map(&:buyer).uniq
      @buyer_daily_cost_total = @buyers.map(&:daily_cost).sum
      @shipping_methods = @orders.map(&:shipping_method).uniq
      @shipping_method_costs_total = @shipping_methods.map(&:daily_cost).sum
    end

    def set_order_buyers
      @date ||= @order.shipping_date
      buyer_ids = Oroshi::Order.non_template.where(shipping_date: @date).pluck(:buyer_id).uniq
      @buyers = Oroshi::Buyer.active.order_by_associated_system_id.where(id: buyer_ids)
    end

    def set_supply_volumes
      @orders = Oroshi::Order.non_template.where(shipping_date: @date)
                             .includes(product_variation: %i[product supply_type_variations supply_type])
      @supply_volumes = calculate_supply_volumes
    end

    def set_order_product_inventories
      query_dates = [@date..@date + 2.days]
      @orders = Oroshi::Order.non_template.where(shipping_date: query_dates)
                             .includes(
                               :product_inventory,
                               product_variation: %i[supply_type supply_type_variations product]
                             )
      @products = Oroshi::Product.with_product_variations
                                 .by_product_variation_count.includes(
                                   product_variations:
                                  %i[product supply_type supply_type_variations
                                     production_zones default_shipping_receptacle]
                                 )
      @grouped_product_inventories = Oroshi::ProductInventory.by_manufacture_date(query_dates)
                                                             .includes(:product_variation, :production_requests)
                                                             .group_by(&:product_variation)
    end

    def calculate_supply_volumes
      @orders.each_with_object({}) do |order, hash|
        volume = calculate_volume(order)
        product_variation = order.product_variation
        product = product_variation.product
        region_name = product_variation.region.name

        hash[region_name] ||= {}
        hash[region_name][product] ||= { total: 0, units: product.supply_type.units }

        add_volume_to_hash(hash, region_name, product, product_variation, volume)
      end
    end

    def calculate_volume(order)
      order.product_variation.primary_content_volume * order.item_quantity
    end

    def add_volume_to_hash(hash, region_name, product, product_variation, volume)
      hash[region_name][product][:total] += volume
      hash[region_name][product][product_variation] ||= 0
      hash[region_name][product][product_variation] += volume
    end

    def set_product_inventories
      @orders = Oroshi::Order.non_template.where(shipping_date: @date)
                             .includes(:product_inventory, product_variation: [:product])
      @product_inventories = @orders.each_with_object({}) do |order, hash|
        product_variation = order.product_variation
        product = product_variation.product

        hash[product] ||= {}
        hash[product][product_variation] ||= [0, 0]
        hash[product][product_variation][0] += order.item_quantity
        hash[product][product_variation][1] += order.product_inventory.quantity
      end
    end

    def params_with_date
      modified_params = params.dup
      %i[shipping_date arrival_date manufacture_date expiration_date].each do |date_param|
        endpoint = modified_params[:oroshi_order]
        endpoint[date_param] = parse_japanese_date(endpoint[date_param])
      end
      modified_params[:oroshi_order][:is_order_template] =
        modified_params[:oroshi_order][:is_order_template].to_i.positive?
      modified_params
    end

    def parse_japanese_date(date_str)
      Date.strptime(date_str, '%Y年%m月%d日') if date_str.present?
    end

    def order_params
      params_with_date.require(:oroshi_order)
                      .permit(:buyer_id, :product_variation_id, :shipping_receptacle_id, :shipping_method_id,
                              :item_quantity, :receptacle_quantity, :freight_quantity, :shipping_cost, :materials_cost,
                              :sale_price_per_item, :adjustment, :note, :is_order_template, :shipping_date,
                              :arrival_date, :bundled_with_order_id, :bundled_shipping_receptacle,
                              :add_buyer_optional_cost, :manufacture_date, :expiration_date, :copy_template)
    end

    def quantity_update_order_params
      params.require('[oroshi_order]').permit(:item_quantity, :receptacle_quantity, :freight_quantity)
    end

    def price_update_order_params
      params.require('[oroshi_order]').permit(:sale_price_per_item)
    end

    def new_order_from_template_params
      params.require('[oroshi_order]').permit(:shipping_date, :item_quantity, :receptacle_quantity, :freight_quantity)
    end

    def create_new_order_from_template
      @order_template = Oroshi::OrderTemplate.find(params[:template_id])
      @order = @order_template.order.dup
      @order.assign_attributes(new_order_from_template_params)
      @order.product_inventory = nil # reset product inventory or else manufacure date set through association will fail
      set_production_dates
      reset_switches
    end

    def set_production_dates
      template_order = @order_template.order
      manufacture_date_distance = (template_order.manufacture_date - template_order.shipping_date).to_i
      expiration_date_distance = (template_order.expiration_date - template_order.manufacture_date).to_i
      @order.manufacture_date = @order.shipping_date + manufacture_date_distance
      @order.expiration_date = @order.manufacture_date + expiration_date_distance
    end

    def reset_switches
      # remove the order template association and make sure the order is not saved as a template
      @order.is_order_template = false
      @order.order_template = nil
      # templates cannot be bundled by default
      @order.bundled_with_order_id = nil
      @order.bundled_shipping_receptacle = false
    end

    def set_input_vars
      @buyers = Oroshi::Buyer.active.order_by_associated_system_id.includes(:shipping_methods)
      @shipping_methods = Oroshi::ShippingMethod.active.includes(:buyers)
      @products = Oroshi::Product.by_product_variation_count.includes(:product_variations, :supply_type)
      @product_variations = Oroshi::ProductVariation.active.includes(:product).group_by(&:product)
      @shipping_receptacles = Oroshi::ShippingReceptacle.active.order(:name, :handle, :cost)
    end

    def handle_dashboard_response(view)
      yield if block_given?
      render partial: "oroshi/orders/dashboard/#{view}"
    end
  end
end
