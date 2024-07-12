json.array!(@rakuten_orders) do |order|
  json.className 'order'
  json.start order.ship_date
  json.end order.ship_date
  json.allDay true
  json.url rakuten_order_path(order.id)
end
