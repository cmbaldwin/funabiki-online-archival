json.array!(@holidays)
json.array!(@order_counts) do |ship_date, count|
  json.title "#{count.to_s}#{('*' unless @new_online_orders.empty?) if @new_online_orders && (ship_date == Time.zone.today)}"
  json.start ship_date
  json.end ship_date
  json.allDay true
  json.className (ship_date == Time.zone.today ? 'new_order_count' : 'order_count')
  json.backgroundColor (ship_date == Time.zone.today ? '#DC7632' : 'rgba(185, 232, 247, 0.24)')
  json.textColor 'black'
  json.borderColor 'rgba(255, 255, 255, 0)'
end
