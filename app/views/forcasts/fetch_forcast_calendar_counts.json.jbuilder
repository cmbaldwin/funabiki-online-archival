json.array!(@holidays)
json.array!(@range) do |date|
  stat = Stat.find_by(date:)
  if stat&.data && stat.date < Time.zone.today
    counts = stat.self_count
    json.className "p-1 count_event cursor-pointer finished_count_event count_tippy_#{date.strftime('%Y_%m_%d')}"
    json.body_text <<~HTML
      <div class='text-black text-center mt-2'>
        #{print_calender_count('殻付き', counts[:shell_count])}
        #{print_calender_count('三倍体', counts[:triploid_count])}
        #{print_calender_count('小殻付き', counts[:bara_count])}
        #{print_calender_count('水切り', counts[:mukimi_count])}
      </div>
    HTML
    json.title
  else
    orders = %w[RakutenOrder YahooOrder FunabikiOrder FurusatoOrder InfomartOrder].map do |model|
      model.constantize.with_date(date)
    end.flatten
    order_count = orders.length
    shell_count = orders.map(&:shell_count).sum
    triploid_count = orders.map(&:triploid_count).sum
    mukimi_count = orders.map(&:mukimi_count).sum
    bara_count = orders.map(&:bara_count).sum
    json.className "p-1 count_event cursor-pointer forcast_count_event count_tippy_#{date.strftime('%Y_%m_%d')}"
    json.body_text <<~HTML.strip_heredoc.html_safe
      <div class='text-black text-center mt-2'>
        #{print_calender_count('殻付き', shell_count) unless shell_count.zero?}
        #{print_calender_count('三倍体', triploid_count) unless triploid_count.zero?}
        #{print_calender_count('小殻付き', bara_count) unless bara_count.zero?}
        #{print_calender_count('水切り', mukimi_count) unless mukimi_count.zero?}
      </div>
    HTML
    json.title "#{order_count}件 (予定)"
  end
  json.description ''
  json.backgroundColor 'rgba(255, 255, 255, 0.24)'
  json.textColor 'black'
  json.borderColor 'rgba(255, 255, 255, 0)'
  json.start stat&.date || date
  json.end stat&.date || date
end
