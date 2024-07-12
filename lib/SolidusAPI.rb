# frozen_string_literal: true

require 'httparty'
# Solidus API wrapper class
class SolidusAPI
  include HTTParty

  attr_reader :current_url, :response, :orders

  def initialize
    @api_url = URI('http://www.funabiki.info/api/')
    @current_url = ''
    @response = ''
    @orders = []
  end

  def query_endpoint(**query)
    return 'No endpoint specified' if query.empty? || query[:endpoint].nil?

    @current_url = "#{@api_url}#{query[:endpoint]}#{'?' unless query[:number]}"
    page_config(**query) unless query[:number]
    query[:number] ? @current_url = "#{@current_url}/#{query[:number]}" : construct_url(**query)
    @response = loop_pages
  end

  def new_orders(**query)
    complete_orders(shipment_state: 'pending', **query)
  end

  def processed_orders(**query)
    complete_orders(shipment_state: 'ready', **query)
  end

  def shipped_orders(**query)
    complete_orders(shipment_state: 'shipped', **query)
  end

  def complete_orders(**query)
    all_orders(state: 'complete', **query)
  end

  def all_orders(**query)
    query_endpoint(endpoint: 'orders', **query)
  end

  def save(order_retrieval_method)
    send(order_retrieval_method)
    fetch_order_details
    save_orders
  end

  def fetch_order_details(orders = current_orders)
    return unless orders

    @orders = orders.map { |order| order(order['number']) }
  end

  def order(number)
    query_endpoint(endpoint: 'orders', number:)
  end

  def save_orders(orders = @orders)
    return unless orders.present?

    orders.each { |order| save_order(order) }
  end

  private

  def auth_header
    {
      "Authorization": "Bearer #{ENV['SOLIDUS_API_KEY']}"
    }
  end

  def page_config(**query)
    return unless query[:page].present? || query[:per_page].present?

    @current_url = "#{@current_url}&page=#{query[:page]}&per_page=#{query[:per_page]}"
  end

  def construct_url(**query)
    composed_query = query.except(:endpoint, :page, :per_page).map do |attribute, value|
      "q[#{attribute}_eq]=#{value}"
    end.join('&')
    @current_url = "#{@current_url}&#{composed_query}"
  end

  def loop_pages(page = 1, url = @current_url, last_res = nil)
    res = self.class.get(url, headers: auth_header)
    return res if res['pages'].nil?

    last_res ? last_res['orders'].concat(res['orders']) : last_res = res
    return last_res unless res['pages'].positive? && res['current_page'] != res['pages']

    next_url = "#{@current_url}&page=#{page + 1}"
    loop_pages(page + 1, next_url, last_res)
  end

  def current_orders(orders = @response['orders'])
    return unless orders.present?

    orders
  end

  def save_order(order)
    FunabikiOrder.unscoped.find_or_create_by(
      order_id: order['number']
    ).update(
      order_time: (DateTime.parse(order['created_at']) if order['created_at']),
      ship_date: (Date.parse(order['shipping_date']) if order['shipping_date']),
      arrival_date: (Date.parse(order['arrival_date']) if order['arrival_date']),
      ship_status: order['shipment_state'],
      data: order.to_json
    )
  end
end
