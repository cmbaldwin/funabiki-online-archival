json.array!(@holidays)

json.array!(@invoices) do |invoice|
  json.extract! invoice, :id, :start_date, :end_date
  json.title "#{to_nengapi(invoice.start_date)}から#{to_nengapi(invoice.end_date - 1.day)}の仕切り書（#{invoice.supplier_organizations.map(&:entity_name).join(' ')}）"
  json.className 'invoice_event'
  json.type 'invoice'
  json.start invoice.start_date
  json.end invoice.end_date + 1.day
  json.allDay true
  json.backgroundColor 'rgba(0, 84, 0, 1)'
  json.textColor 'white'
  json.borderColor 'rgba(255, 255, 255, 0)'
  json.url oroshi_invoice_url(invoice)
  json.order(-999999)
end

filtered_supply_dates = @supply_dates.select do |supply_date|
  variations = supply_date.supply_date_supply_type_variations
  total = variations.map { |v| [v, v.total] }.sum(&:last)
  total.positive?
end

json.array!(filtered_supply_dates) do |supply_date|
  json.className 'bg-success bg-opacity-20'
  json.start supply_date.date
  json.allDay true
  json.display 'background'
end

type_variation_joins = filtered_supply_dates.flat_map do |supply_date|
  supply_date.supply_date_supply_type_variations.select { |join| join.total.positive? }
end

json.array!(type_variation_joins) do |join|
  variation = join.supply_type_variation
  json.title "#{variation} #{join.total}#{variation.units}"
  json.start join.supply_date.date
  json.allDay true
  json.url oroshi_supply_date_path(join.supply_date.date)
  json.order(-join.total)
end
