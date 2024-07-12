json.array!(@funabiki_orders) do |order|
  json.className 'order'
  json.start order.ship_date
  json.end order.ship_date
  json.allDay true
  json.url '#'
end
