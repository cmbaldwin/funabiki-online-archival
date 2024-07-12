module MessagesHelper
  def get_messages
    Message.where(user: current_user.id).order(:created_at).reverse.last(10)
  end

  def status_icon(message)
    case message.status
    when :error
      icon('exclamation-triangle', class: 'text-danger ms-1')
    when :processing
      content_tag(:div, class: 'spinner-border spinner-border-sm text-primary ms-2', role: 'status') do
        content_tag(:span, '処理中…', class: 'visually-hidden')
      end
    when :completed
      icon('check2-circle', class: 'text-success ms-1')
    end
  end

  def print_model(model)
    {
      'supply_check' => '原料受け入れチェック表',
      'oyster_supply' => '牡蠣原料',
      'profit' => '計算表',
      'manifest' => 'Infomart/Funabiki.infoの出荷表',
      'rakuten_manifest' => '楽天出荷表',
      'rakuten_process' => '楽天自動処理',
      'rakuten_refresh' => '楽天データ更新',
      'refresh_funabiki' => '楽天データ更新',
      'yahoo_shipping_list' => 'ヤフー出荷表',
      'funabiki_shipping_list' => 'Funabiki.info出荷表',
      'infomart_shipping_list' => 'Infomart出荷表',
      'oyster_invoice' => '牡蠣原料仕切り',
      'oroshi_invoice' => '供給仕切り書',
      'send_invoice_mail' => '牡蠣原料仕切りメール送信',
      'send_oroshi_invoice_mail' => '供給の仕切り書メール送信',
      'expiration_card' => '消(費・味)期限カード',
      'update_yahoo' => 'ヤフーショッピングデータ更新',
      'reciept' => '領収証'
    }[model]
  end

  def print_message_data(message)
    @message = message
    return unless @message&.state

    @data = @message.data
    send "print_#{@message.model}_data"
  end

  def download_path
    download_message_path(@message, file_name: @message&.stored_file&.blob&.filename || '')
  end

  def print_oyster_invoice_data
    if @data[:invoice_id].zero?
      render html: link_to("#{@data[:invoice_preview][:start_date]}~の#{@data[:invoice_preview][:end_date] - 1.day}
        (#{invoice_location(@data[:invoice_preview][:location])}-#{invoice_format(@data[:invoice_preview][:format])})
        仕切りプレビュー", download_path, class: 'card-link', target: '_blank').html_safe
    else
      begin
        invoice = OysterInvoice.find(@data[:invoice_id])
        start_nengapi = Date.parse(invoice.start_date).strftime('%Y年%m月%d日')
        end_nengapi = (Date.parse(invoice.end_date) - 1.day).strftime('%Y年%m月%d日')
        render html: link_to("#{start_nengapi}~#{end_nengapi}仕切り", invoice, class: 'card-link').html_safe
      rescue ActiveRecord::RecordNotFound
        render html: "<p class='small text-warning'>エラー:　仕切り##{@data[:invoice_id]}をみつけられませんでした。</p>".html_safe
      end
    end
  end

  def invoice_location(location)
    location == 'sakoshi' ? '坂越' : '相生'
  end

  def invoice_format(format)
    format == 'union' ? '組合版' : '個人版'
  end

  def print_oroshi_invoice_data
    if @data[:invoice_id].zero?
      supplier_organization = Oroshi::SupplierOrganization
                              .find(@data[:invoice_preview][:supplier_organization]).entity_name
      render html: link_to("#{@data[:invoice_preview][:start_date]}~の#{@data[:invoice_preview][:end_date]}
                            (#{supplier_organization}-
                            #{oroshi_invoice_layout(@data[:invoice_preview][:layout])}}-
                            #{oroshi_invoice_format(@data[:invoice_preview][:invoice_format])})
                            仕切りプレビュー".squish,
                           download_path,
                           class: 'card-link',
                           target: '_blank').html_safe
    else
      begin
        invoice = Oroshi::Invoice.find(@data[:invoice_id])
        start_nengapi = to_nengapi(invoice.start_date)
        end_nengapi = to_nengapi(invoice.end_date - 1.day)
        render html: link_to("#{start_nengapi}~#{end_nengapi}仕切り書", invoice, class: 'card-link').html_safe
      rescue ActiveRecord::RecordNotFound
        render html: "<p class='small text-warning'>エラー:　仕切り##{@data[:invoice_id]}をみつけられませんでした。</p>".html_safe
      end
    end
  end

  def oroshi_invoice_layout(layout)
    layout == 'standard' ? '標準版' : '簡易版'
  end

  def oroshi_invoice_format(invoice_format)
    invoice_format == 'organization' ? '組織版' : '個人版'
  end

  def print_send_invoice_mail_data
    render html: "#{to_nengapijibun(Time.zone.now)}に<br>メールはを送信しました。".html_safe
  end

  def print_send_oroshi_invoice_mail_data
    render html: "#{to_nengapijibun(Time.zone.now)}に<br>メールはを送信しました。".html_safe
  end

  def print_supply_check_data
    oyster_supply = Oroshi::SupplyDate.find_by(date: @data[:supply_date])
    render html: link_to("#{I18n.l(oyster_supply.date, format: :long)}原料受入れチェック表",
                         download_path, class: 'card-link', target: '_blank').html_safe
  rescue StandardError
    render html: "<p class='small text-warning'>エラー:　原料受入れ##{@data[:oyster_supply_id]}をみつけられませんでした。</p>".html_safe
  end

  def print_oyster_supply_data
    oyster_supply = OysterSupply.find(@data[:oyster_supply_id])
    render html: link_to("#{oyster_supply.supply_date}原料受入れチェック表",
                         download_path, class: 'card-link', target: '_blank').html_safe
  rescue StandardError
    render html: "<p class='small text-warning'>エラー:　原料受入れ##{@data[:oyster_supply_id]}をみつけられませんでした。</p>".html_safe
  end

  def print_rakuten_manifest_data
    render html: link_to(
      "楽天#{'と通販全部' if @data[:include_tsuhan]}#{if @data[:seperated]
                                                 ' 商品分別版 '
                                               end}出荷表（#{@data[:search_date]}）", download_path, class: 'card-link', target: '_blank'
    ).html_safe
  rescue StandardError
    render html: "<p class='small text-warning'>エラー:　出荷表エラーが発生した。</p>".html_safe
  end

  def print_rakuten_refresh_data
    render html: "完成しました...#{link_to('リフレッシュ', rakuten_orders_path)}".html_safe
  rescue StandardError
    render html: "<p class='small text-warning'>エラー:　エラーが発生した。</p>".html_safe
  end

  def print_refresh_funabiki_data
    render html: "完成しました...#{link_to('リフレッシュ', funabiki_orders_path)}".html_safe
  rescue StandardError
    render html: "<p class='small text-warning'>エラー:　エラーが発生した。</p>".html_safe
  end

  def print_rakuten_process_data
    print_rakuten_refresh_data
  end

  def print_manifest_data
    @manifest = Manifest.find(@data[:manifest_id])
    render html: link_to("InfoMart/Funabiki.infoの出荷表（#{@manifest.sales_date})", download_path,
                         class: 'card-link', target: '_blank').html_safe
  rescue StandardError
    render html: "<p class='small text-warning'>エラー:　出荷表##{@data[:oyster_supply_id]}をみつけられませんでした。</p>".html_safe
  end

  def print_infomart_shipping_list_data
    render html: link_to("Infomart出荷表（#{@message.data[:ship_date]})", download_path,
                         class: 'card-link', target: '_blank').html_safe
  rescue StandardError
    render html: "<p class='small text-warning'>エラー:　出荷表##{@data[:oyster_supply_id]}をみつけられませんでした。</p>".html_safe
  end

  def print_funabiki_shipping_list_data
    render html: link_to("Funabiki.info出荷表（#{@message.data[:ship_date]})", download_path,
                         class: 'card-link', target: '_blank').html_safe
  rescue StandardError
    render html: "<p class='small text-warning'>エラー:　出荷表##{@data[:oyster_supply_id]}をみつけられませんでした。</p>".html_safe
  end

  def print_yahoo_shipping_list_data
    render html: link_to("ヤフー出荷表（#{@message.data[:ship_date]})", download_path, class: 'card-link',
                                                                                target: '_blank').html_safe
  rescue StandardError
    render html: "<p class='small text-warning'>エラー:　出荷表##{@data[:oyster_supply_id]}をみつけられませんでした。</p>".html_safe
  end

  def print_reciept_data
    render html: link_to(@message.stored_file.filename, download_path, class: 'card-link',
                                                                       target: '_blank').html_safe
  rescue StandardError
    render html: "<p class='small text-warning'>エラー:　領収証保存出来なかった".html_safe
  end

  def print_update_yahoo_data
    render html: link_to('リフレッシュ', root_path).html_safe
  rescue StandardError
    render html: "<p class='small text-warning'>エラー:　管理者へ連絡してください。</p>".html_safe
  end

  def print_expiration_card_data
    render html: link_to('カード一覧', expiration_card_path).html_safe if @message.state
  end
end
