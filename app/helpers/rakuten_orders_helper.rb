module RakutenOrdersHelper

  def type_counts
    return {} unless @daily_orders && @search_date

    upsell_counts(count_items)
  end

  def count_items
    @daily_orders.each_with_object({}) do |order, hash|
      order_counts = order.type_counts(@search_date)
      order_counts.each {|type, count| hash[type] = (hash[type] || 0) + count }
    end
  end

  def upsell_counts(counts)
    upsell_products.each do |count, search_term|
      next unless count.positive?

      type = EcProductType.where("name ILIKE ?", "%#{search_term}%").first.id
      counts[type] = (counts[type] || 0) + count
    end
    counts
  end

  def upsell_products
    [[upsell_count('knife_count'), 'ナイフ'], 
     [upsell_count('tsukudani_set'), '佃煮'], 
     [upsell_count('sauce_set'), 'Oyster 38']]
  end

  def upsell_count(method_str)
    @daily_orders.reduce(0){ |m,o| m += o.send("#{method_str}") } if @daily_orders
  end

  def status_badge_color(status)
    {
      100 => "warning", #'注文確認待ち',
      200 => "info", #'楽天処理中',
      300 => "primary", #'発送待ち',
      400 => "info", #'変更確定待ち',
      500 => "success", #'発送済',
      600 => "warning", #'支払手続き中',
      700 => "info", #'支払手続き済',
      800 => "danger", #'キャンセル確定待ち',
      900 => "danger" #'キャンセル確定'
    }[status]
  end

  def alternate_arrival(order)
    order.arrival_date != (@search_date + 1.day)
  end

end
