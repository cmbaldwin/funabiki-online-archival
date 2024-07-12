json.array!(@holidays)
json.array!(@order_counts) do |ship_date, count|
	json.title count.to_s
	json.start ship_date
	json.end ship_date
	json.allDay true
	json.className 'order_count'
	json.backgroundColor 'rgba(185, 232, 247, 0.24)'
	json.textColor 'black'
	json.borderColor 'rgba(255, 255, 255, 0)'
end