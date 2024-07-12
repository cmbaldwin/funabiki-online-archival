module ApplicationHelper
  include ShopsHelper

  def get_setting(settings, setting_name)
    settings&.settings&.dig(setting_name)
  end

  def create_chart(chart_params)
    method(chart_params[:chart_type]).call method("#{chart_params[:chart_path]}_path").call,
                                           **chart_params[:init_params]
  end

  def exp_card_popover(expiration_card)
    "<small>
      <div class='container m-0 p-0'>
        <div class='row m-0 p-0'>
          <div class='float-start w-25 font-weight-bolder m-0 p-0 border-bottom'>名称</div>
          <div class='float-end w-75 m-0 p-0 pl-2 border-bottom'>#{expiration_card.product_name}</div>
        </div>
        <div class='row m-0 p-0'>
          <div class='float-start w-25 font-weight-bolder m-0 p-0 border-bottom'>加工所所在地</div>
          <div class='float-end w-75 m-0 p-0 pl-2 border-bottom'>#{expiration_card.manufacturer_address}</div>
        </div>
        <div class='row m-0 p-0'>
          <div class='float-start w-25 font-weight-bolder m-0 p-0 border-bottom'>加工者</div>
          <div class='float-end w-75 m-0 p-0 pl-2 border-bottom'>#{expiration_card.manufacturer}</div>
        </div>
        <div class='row m-0 p-0'>
          <div class='float-start w-25 font-weight-bolder m-0 p-0 border-bottom'>採取海域</div>
          <div class='float-end w-75 m-0 p-0 pl-2 border-bottom'>#{expiration_card.ingredient_source}</div>
        </div>
        <div class='row m-0 p-0'>
          <div class='float-start w-25 font-weight-bolder m-0 p-0 border-bottom'>用途</div>
          <div class='float-end w-75 m-0 p-0 pl-2 border-bottom'>#{expiration_card.consumption_restrictions}</div>
        </div>
        <div class='row m-0 p-0'>
          <div class='float-start w-25 font-weight-bolder m-0 p-0 border-bottom'>保存温度</div>
          <div class='float-end w-75 m-0 p-0 pl-2 border-bottom'>#{expiration_card.storage_recommendation}</div>
        </div>
        #{if expiration_card.made_on
            "<div class='row m-0 p-0'>
            <div class='float-start w-25 font-weight-bolder m-0 p-0 border-bottom'>保存温度</div>
            <div class='float-end w-75 m-0 p-0 pl-2 border-bottom'>#{expiration_card.manufactuered_date}</div>
          </div>"
          end}
        <div class='row m-0 p-0'>
          <div class='float-start w-25 font-weight-bolder m-0 p-0'>#{expiration_card.print_shomiorhi}</div>
          <div class='float-end w-75 m-0 mb-2 p-0 pl-2'>#{expiration_card.expiration_date}</div>
        </div>
      </div>
    </small>"
  end

  def title(page_title)
    content_for(:title) { page_title }
  end

  def weekday_japanese(num)
    # d.strftime("%w") to Japanese
    weekdays = { 0 => '日', 1 => '月', 2 => '火', 3 => '水', 4 => '木', 5 => '金', 6 => '土' }
    weekdays[num]
  end

  def to_nengapi(date)
    date&.strftime('%Y年%m月%d日')
  end

  def to_gapi(date)
    date&.strftime('%m月%d日')
  end

  def to_nengapiyoubi(date)
    date&.strftime("%Y年%m月%d日 (#{weekday_japanese(date.wday)})")
  end

  def to_gapiyoubi(date)
    date&.strftime("%m月%d日 (#{weekday_japanese(date.wday)})")
  end

  def to_nengapijibun(date)
    date&.strftime('%Y年%m月%d日%H時%M分')
  end

  def to_jibun(date)
    date&.strftime('%H時%M分')
  end

  def yenify(number)
    ActionController::Base.helpers.number_to_currency(number, locale: :ja, unit: '')
  end

  def yenify_with_decimal(number)
    ActionController::Base.helpers.number_to_currency(number, locale: :ja, unit: '', precision: 1)
  end

  def cycle_table_rows
    cycle('even', 'odd')
  end

  def nengapi_today
    Time.zone.today.strftime('%Y年%m月%d日')
  end

  def nengapi_today_plus(number)
    (Time.zone.today + number).strftime('%Y年%m月%d日')
  end

  def icon(icon, options = {})
    classes = "bi bi-#{icon}"
    classes += " #{options[:class]}" if options[:class].present?
    style = ""
    style = "font-size: #{options[:size]}px; width: #{options[:size]}px; height: #{options[:size]}px;" if options[:size].present?
    "<i class='#{classes}' style='#{style}'></i>".html_safe
  end

  def get_infomart_backend_link(backend_id)
    'https://www2.infomart.co.jp/trade/trade_detail.page?14&tid=' + backend_id + '&del_hf=1&through_status_code&returned_flg'
  end

  def online_order_counts(orders)
    counts = {}
    types_arr = %w[生むき身 生セル 小殻付 セルカード 冷凍むき身 冷凍セル 穴子(件) 穴子(g) 干しムキエビ(100g) 干し殻付エビ(100g) タコ サーモン Oyster38 サムライ佃煮 サムライゴールド]
    types_arr.each { |w| counts[w] = 0 }
    orders.each do |order|
      next if order.cancelled

      order.counts.each_with_index do |count, i|
        counts[types_arr[i]] += count
      end
    end
    cards = counts.values[3]
    anago = counts.values[7]
    results = { headers: counts.keys, values: counts.values, anago:, cards: }
    ['セルカード', '穴子(g)'].each do |t|
      i = results[:headers].index(t)
      %i[headers values].each { |k| results[k].delete_at(i) }
    end
    results
  end

  def yahoo_knife_counts(orders)
    orders.map { |o| o.knife_count unless o.item_ids.nil? }.compact.sum
  end

  def yahoo_order_counts(orders)
    counts = {}
    types_arr = %w[生むき身 生セル 小殻付 セルカード 冷凍むき身 冷凍セル 穴子(件) 穴子(g) 干しムキエビ(80g) 干し殻付エビ(80g) タコ サーモン Oyster38 サムライ佃煮　サムライゴールド]
    types_arr.each { |w| counts[w] = 0 }
    count_hash = {
      'kakiset302' => [2, 30, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'kakiset202' => [2, 20, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'kakiset301' => [1, 30, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'kakiset201' => [1, 20, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'kakiset101' => [1, 10, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'karatsuki100' => [0, 100, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'karatsuki50' => [0, 50, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'karatsuki40' => [0, 40, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'karatsuki30' => [0, 30, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'karatsuki20' => [0, 20, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'karatsuki10' => [0, 10, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'mukimi04' => [4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'mukimi03' => [3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'mukimi02' => [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'mukimi01' => [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pkara100' => [0, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pkara50' => [0, 0, 0, 0, 0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pkara40' => [0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0],
      'pkara30' => [0, 0, 0, 0, 0, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pkara20' => [0, 0, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pkara10' => [0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pmuki04' => [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pmuki03' => [0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pmuki02' => [0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pmuki01' => [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'tako1k' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
      'tako1k2-3b' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
      'mebi80x5' => [0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0],
      'mebi80x3' => [0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0],
      'hebi80x10' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0],
      'hebi80x5' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0],
      'anago600' => [0, 0, 0, 0, 0, 0, 1, 600, 0, 0, 0, 0, 0, 0, 0],
      'anago480' => [0, 0, 0, 0, 0, 0, 1, 480, 0, 0, 0, 0, 0, 0, 0],
      'anago350' => [0, 0, 0, 0, 0, 0, 1, 350, 0, 0, 0, 0, 0, 0, 0],
      'syoukara1kg' => [0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'syoukara2kg' => [0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'syoukara3kg' => [0, 0, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'syoukara5kg' => [0, 0, 5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'reoysalmon' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
      'oyster38' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
      'tsukuani' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0],
      'tsukudani' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0],
      'tsukuani6' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0],
      'tsukudani6' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0],
      'sbt-10' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10],
      'sbt-20' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20],
      'sbt-30' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 30],
      'sbt-40' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 40],
      'sbt-50' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50],
      'sbt-60' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 60],
      'sbt-70' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 70],
      'sbt-80' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80],
      'sbt-90' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 90],
      'sbt-100' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100]
    }
    orders.each do |order|
      next if order.item_ids.nil? # unless cancelled or no item ids

      order.item_ids.each do |item_id|
        count_hash[item_id].each_with_index do |count, i|
          counts[types_arr[i]] += count if counts[types_arr[i]]
        end
      end
    end
    cards = counts.values[3]
    anago = counts.values[7]
    results = { headers: counts.keys, values: counts.values, anago:, cards: }
    ['セルカード', '穴子(g)'].each do |t|
      i = results[:headers].index(t)
      %i[headers values].each { |k| results[k].delete_at(i) }
    end
    results
  end

  def online_order_counts_counter(i)
    %W[\u30D1\u30C3\u30AF \u500B kg \u679A \u30D1\u30C3\u30AF \u500B \u4EF6 g \u30D1\u30C3\u30AF \u30D1\u30C3\u30AF
       \u4EF6 \u679A \u672C \u30D1\u30C3\u30AF \u500B][i]
  end

  def online_order_knives(orders)
    orders.map { |o| o.knife }.sum
  end

  def online_order_noshis(orders)
    orders.map { |o| o.noshi }.sum
  end

  def infomart_count_counter(i)
    %W[\u30D1\u30C3\u30AF \u5186\u76E4 \u500B \u30D1\u30C3\u30AF \u30D1\u30C3\u30AF \u500B \u30B1\u30FC\u30B9
       \u30B1\u30FC\u30B9 \u672C][i]
  end

  def infomart_count_title(i)
    # [ nama_500, nama_1k, nama_shell, frz_l, frz_ll, frz_shell_co, frz_shell_hako, jp_shell, oyster38 ]
    ['生むき身 500g', '生むき身 1k', '生殻付き牡蠣', 'デカプリ 500g (L)', 'デカプリ 500g (LL)', '冷凍殻付き牡蠣（1個）', '冷凍殻付き牡蠣（100個単位）',
     '小 冷凍殻付き牡蠣（120個単位）', 'Oyster38'][i]
  end

  def infomart_counts(orders)
    counts = orders.map { |order| order.counts unless order.cancelled }
    counts.each_with_object([0, 0, 0, 0, 0, 0, 0, 0, 0]) do |c, m|
      c&.each_with_index { |v, i| m[i] += v }
    end
  end

  def item_count_table(orders)
    counts_table = item_counts(orders).map { |type, count| item_count_cell_array(type, count) }
    create_count_table(counts_table)
  end

  def item_count_cell_array(type, count)
    if type.respond_to?(:name) && type.respond_to?(:counter)
      [type.name, "#{count}#{type.counter}"]
    else
      [type, count.to_s]
    end
  end

  def item_counts(orders)
    orders.map(&:item_ids_counts).each_with_object({}) do |order, memo|
      order.each { |item_id, count| accumulate_counts(item_id, count, memo) }
    end
  end

  def accumulate_counts(item_id, count, memo)
    products = EcProduct.with_reference_id(item_id)
    error_to_memo(memo, item_id, count) unless products.any?

    products.each do |product|
      if product
        memo[product.ec_product_type] ||= 0
        memo[product.ec_product_type] += count * product.quantity.to_i
      else
        memo[item_id] ||= 0
        memo[item_id] += count
      end
    end
  end

  def error_to_memo(memo, item_id, count)
    memo[item_id] ||= 0
    memo[item_id] += count
  end

  def create_count_table(counts_table)
    content_tag(:div, class: 'row align-items-center text-center m-1 mb-2') do
      counts_table.map do |type, count|
        content_tag(:div, class: 'col-lg-3 col-6 mb-2') do
          content_tag(:h6, type, class: 'font-weight-bolder p-2') +
            content_tag(:span, count, class: 'btn btn-sm btn-primary').html_safe
        end
      end.join.html_safe
    end
  end
end
