json.array!(@holidays)
json.array!(@oyster_supply) do |supply|
  case @place
  when 'supply_index'
    json.title supply_title(supply)
  when 'supply_show'
    json.title ''
  end
  json.start DateTime.strptime(supply.supply_date, '%Y年%m月%d日')
  json.allDay true
  json.className "supply_event tippy_#{supply.id}"
  json.supply_id supply.id
  json.description current_user.admin? ? supply_description(supply) : ''
  json.backgroundColor supply.check_completion.empty? ? 'rgba(185, 232, 247, 0.24)' : '#DC7632'
  json.textColor 'black'
  json.borderColor 'rgba(255, 255, 255, 0)'
  json.url oyster_supply_url(supply)
end
if @place == 'supply_index'
  json.array!(@oyster_invoices) do |invoice|
    start_date = DateTime.strptime(invoice.start_date, '%Y-%m-%d')
    end_date = DateTime.strptime(invoice.end_date, '%Y-%m-%d')
    json.extract! invoice, :id, :start_date, :end_date
    json.title "#{to_nengapi(start_date)}から#{to_nengapi(end_date - 1.day)}の仕切り"
    json.className 'invoice_event'
    json.type 'invoice'
    json.start start_date
    json.end end_date
    json.allDay true
    json.backgroundColor 'rgba(0, 84, 0, 1)'
    json.textColor 'white'
    json.borderColor 'rgba(255, 255, 255, 0)'
    json.url oyster_invoice_url(invoice)
  end
end
