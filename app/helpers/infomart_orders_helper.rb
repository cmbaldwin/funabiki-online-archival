module InfomartOrdersHelper

  def print_destination(order)
    order.destination[/.*(?=\（)/]
  end

  def food?(item)
    (item[:name].include?('箱代') || item[:name].include?('送料')) ? false : true 
  end

  def cold?(item)
    item[:name].include?('冷') ? true : false
  end

  def status_badge_color(order)
    {
      "発注済" => "badge-warning",
      "発送済" => "badge-primary",
      "受領" => "badge-success",
      "ｷｬﾝｾﾙ(取引)" => "badge-danger"
    }[order.status]
  end

end
