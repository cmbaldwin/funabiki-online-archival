module YahooOrdersHelper

  def status_color(order)
    s = order.order_status
    unless order.ship_date == nil
      if s == 1 || s ==  2 || s ==  3
        "info"
      elsif s == 5
        "success"
      else
        "danger"
      end
    else
      "warning"
    end
  end

  def print_shipping_name(order)
    if order.billing_name != order.shipping_name
      order.shipping_name
    else
      '""'
    end
  end

end
