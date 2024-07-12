module OnlineOrdersHelper

  def status_badge_color(order_status)
    {
      "processing" => "primary",
      "cancelled" => "danger",
      "on-hold" => "warning",
      "completed" => "success",
    }[order_status]
  end

  def frozen(product_id)
    result = false
    { [437, 516, 517, 519, 520, 521, 838, 522, 837, 523, 13867, 13883, 13884, 13885, 583, 581, 580, 579, 578, 577, 6555, 6556, 6557, 6558, 6559, 6560, 584, 590, 591, 592, 593, 594, 596, 595, 598, 599, 600, 597, 572, 575, 576, 500, 6319, 14375, 14418, 14430] => false,
      [524, 645, 646, 6554, 13551, 13552, 13585, 13584, 13583, 13582, 13580, 13579, 13577, 13586, 13587, 13588, 14252] => true }.each do |id_array, bool|
        result = bool if id_array.include?(product_id)
    end
    result
  end

  def non_zero_print(int)
    int > 0 ? int.to_s : ""
  end

  def date_fix
    unless @daily_orders.nil?
      date = @daily_orders.last.ship_date
    else
      date = @search_date
    end
    date = Time.zone.today if date.nil?
    "#{date.day}日(#{weekday_japanese(date.wday)})"
  end

end
