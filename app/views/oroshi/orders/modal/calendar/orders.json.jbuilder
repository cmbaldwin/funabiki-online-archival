json.array!(@holidays)

json.array!(@orders_by_date) do |date, count|
  json.start date
  json.title count.to_s
  json.url oroshi_orders_path(date: date)
end
