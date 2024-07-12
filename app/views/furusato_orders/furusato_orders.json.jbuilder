json.array!(@furusato_orders) do |order|
  start_date = order.est_shipping_date
  end_date = order.est_shipping_date
  json.className 'order'
  json.start start_date
  json.end end_date
  json.allDay true
  json.url furusato_order_path(order.id)
end
