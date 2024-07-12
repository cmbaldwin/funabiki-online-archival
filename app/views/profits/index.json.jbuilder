json.array!(@holidays)
json.array!(@calendar_profits) do |profit|
  json.title (profit.totals[:profits].nil? || profit.totals.empty?) ? ('未計算') : ('￥' + yenify(profit.totals[:profits]) + print_ampm(profit))
  json.start DateTime.strptime(profit.sales_date, '%Y年%m月%d日')
  json.id profit.id
  json.allDay true
  json.className 'profit_event cursor-pointer'
  unless profit.alone?
    if profit.check_ampm
      json.backgroundColor 'rgba(185, 232, 247, 0.24)'
      json.textColor 'black'
    end
  end
  json.borderColor 'rgba(255, 255, 255, 0)'
  json.url profit_url(profit)
end
