class InfomartOrder < ApplicationRecord
  belongs_to :stat, optional: true

  serialize :items
  serialize :csv_data

  default_scope { where.not(status: 'ｷｬﾝｾﾙ(取引)') }
  scope :with_date, ->(dates) { where(ship_date: [dates]) }
  scope :with_dates, ->(date_range) { where(ship_date: date_range) }
  scope :this_season, -> { where(ship_date: ShopsHelper.this_season_start..ShopsHelper.this_season_end) }
  scope :prior_season, -> { where(ship_date: ShopsHelper.prior_season_start..ShopsHelper.prior_season_end) }

  def shipping_date
    ship_date || order_time.to_date
  end

  def dekapuri_count
    counts[3] + counts[4] + counts[5]
  end

  def mukimi_sales_estimate
    return 0 unless mukimi_count.positive?

    mukimi = items.values.map do |item|
      codified = codify_item(item)
      nama_mukimi = (codified[0] == 'n') && (codified[1] == 'mk')
      item[:subtotal].to_i if nama_mukimi
    end
    mukimi.compact.sum
  end

  def mukimi_per_pack_sales
    return 0 unless mukimi_count.positive?

    mukimi_sales_estimate / mukimi_count
  end

  def mukimi_profit_estimate
    return 0 unless mukimi_count.positive?

    (mukimi_sales_estimate - (raw_oyster_costs(shipping_date).values[0] + (60 * mukimi_count))).to_i
  end

  def pack_profit_estimate
    return 0 unless mukimi_count.positive?

    mukimi_profit_estimate / mukimi_count
  end

  def backend_id
    "1#{items['1'][:transaction_id]}"
  end

  def cancelled
    status == 'ｷｬﾝｾﾙ(取引)'
  end

  def arrival_gapi
    return '指定なし' unless arrival_date

    arrival_date.strftime('%m月%d日')
  end

  def short_destination
    destination[/.*(?=（)/]
  end

  def total_price
    items.values.map { |i| i[:order_total].to_i unless i[:order_total].to_i.zero? }.compact.first
  end

  def non_product_items
    items.values.select { |item| codify_item(item).length < 3 }
  end

  def product_items
    items.values.select { |item| codify_item(item).length > 2 }
  end

  def irrelevant_item(codified_item)
    (codified_item[0] == 'sr') || (codified_item[0] == 'hd')
  end

  def item_array
    items.each_with_object({ raw: [], frozen: [] }) do |(_, item), items_array|
      next if item[:item_code].blank?

      count = [0, 0, 0, 0, 0, 0, 0, 0, 0]
      codified_item = codify_item(item)
      add_item_to_count(item, count)
      next if irrelevant_item(codified_item)

      # ['#', '飲食店', '500g', 'セル', 'その他', 'お届け日', '時間', '備考']
      items_array[:raw] << raw_array(count) if codified_item[0] != 'r'
      # ['#', '飲食店', '500g (L)', '500g (LL)', 'セル', 'お届け日', '時間', '備考']
      items_array[:frozen] << frozen_array(count) if codified_item[0] == 'r'
    end
  end

  def raw_array(count)
    [
      destination,
      count[0].zero? ? '' : "#{count[0]}p",
      count[2].zero? ? '' : "#{count[2]}個",
      "#{'Oyster38' + count[8].to_s + '本' if count[8] > 0}" + "#{count[1].to_s + '枚' if count[1] > 0}",
      arrival_gapi,
      '午前　14-16',
      ' '
    ]
  end

  def frozen_array(count)
    [
      destination,
      count[3].zero? ? '' : "#{count[3]}p",
      count[4].zero? ? '' : "#{count[4]}p",
      "#{count[5].to_s + '個' if count[5] > 0}" + "#{count[6].to_s + '箱' if count[6] > 0}" + "#{count[7].to_s + '個(小)' if count[7] > 0}",
      arrival_gapi,
      '午前　14-16',
      ' '
    ]
  end

  def item_ids_counts
    items.values.map do |item|
      next if irrelevant_item(codify_item(item))

      [item[:item_code], item[:quantity].to_i]
    end.compact
  end

  def item_codes
    items.values.pluck(:item_code)
  end

  def codified_items
    items.values.map { |item| codify_item(item) }
  end

  def codify_item(item)
    item[:item_code].split('-')
  end

  def fix_item_date(i, item_array, &parse_csv_date)
    position = items[i]
    position[:status] = item_array[3]
    position[:name] = item_array[14]
    position[:order_date] = parse_csv_date.call(item_array[32])
    position[:ship_date] = parse_csv_date.call(item_array[33])
    position[:settlement_date] = parse_csv_date.call(item_array[34])
    position[:completion_date] = parse_csv_date.call(item_array[35])
  end

  def fix_item_dates
    parse_csv_date = ->(date) { Date.strptime(date, '%Y/%m/%d') if date.present? }
    csv_data.each { |i, item_array| fix_item_date(i, item_array, &parse_csv_date) }
    items.each { |i, ihash| items.delete(i) if ihash[:ship_date] != ship_date }
    save
  end

  def add_item_to_count(item, count)
    #      0         1         2         3       4          5            6         7         8
    # [ nama_500, nama_1k, nama_shell, frz_l, frz_ll, frz_shell_co, frz_shell_hako, jp_shell, sauce ]
    codified_item = codify_item(item)
    return unless codified_item

    in_box = item[:in_box_quantity].to_i.zero? ? 1 : item[:in_box_quantity].to_i
    quantity = item[:quantity].to_i * in_box
    if codified_item[0] == 'r' # Frozen
      if codified_item[1] == 'sh' # Shells
        if codified_item[3] == 'lg' # Normal
          if item[:in_box_counter] == '箱'
            count[6] += quantity
          elsif item[:in_box_counter] == '個'
            count[5] += quantity
          end
        elsif codified_item[3] == 'xl' # XLarge
          count[6] += quantity
        elsif codified_item[3] == 'sm' # Small
          count[7] += quantity
        end
      elsif codified_item[1] == 'dp'
        if codified_item[2] == 's'
          if codified_item[3] == 'lg'
            unless codified_item[4].include?('n') # eg WDI 20x生食用 has "20n", product discontinued...
              count[3] += quantity
            end
          else # LL
            count[4] += quantity
          end
        else # Okayama
          count[5] += 1
        end
      end
    elsif codified_item[0] == 'n'
      if codified_item[1] == 'sh'
        count[2] += quantity
      elsif codified_item[1] == 'mk'
        count[0] += quantity
      end
    elsif codified_item[0] == 'os38'
      count[8] += quantity
    end
  end

  def counts
    count = [0, 0, 0, 0, 0, 0, 0, 0, 0]
    items_fix = items.clone
    items_fix.each { |_, item| add_item_to_count(item, count) if item[:item_code] }
    count
  end

  def rf_item_count(type)
    item_array[type].length
  end
end
