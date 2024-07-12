module WelcomeHelper
  def card_link(card, title, add_class)
    if card
      link_to title,
              download_expiration_card_path(card, file_name: card&.file&.blob&.filename&.to_s || ''),
              class: 'btn exp_card ' + add_class,
              target: '_blank',
              data: {
                controller: 'tippy',
                tippy_content: exp_card_popover(card),
                turbo_prefetch: false
              }
    else
      link_to title,
              new_expiration_card_path,
              class: 'btn disabled ' + add_class,
              target: '_blank'
    end
  end

  def rakuten_order_link(id)
    'https://order-rp.rms.rakuten.co.jp/order-rb/individual-order-detail-sc/init?orderNumber=' + id
  end

  def time_since_update(model)
    return unless model.order(updated_at: :desc)&.first&.updated_at.present?

    datetime = model.order(updated_at: :desc)&.first&.updated_at
    "#{time_ago_in_words(datetime)}前に更新した"
  end

  def rakuten_noshi_names(daily_orders, search_date)
    daily_orders.map do |order|
      order.packages.map do |pkg|
        next unless order.ship_date(pkg) == search_date && !order.noshi.empty?

        order.sender_family_name
      end
    end.flatten.compact.uniq
  end

  def rakuten_noshi_links(daily_orders, search_date)
    # Second pass: generate the links
    rakuten_noshi_names(daily_orders, search_date).map do |name|
      link_to((name + icon('box-arrow-in-up-right')).html_safe,
              "https://noshi.onrender.com/noshis/new/12/#{name}/御祝",
              target: '_blank',
              data: { turbo_prefetch: false })
    end.join('<br>').html_safe
  end
end
