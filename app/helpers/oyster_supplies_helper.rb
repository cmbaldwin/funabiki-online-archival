# rubocop:disable Metrics/ModuleLength

module OysterSuppliesHelper
  def number_to_circular(num)
    int = num.to_i
    return unless int.positive? && int < 20

    (9312..9331).map { |i| i.chr(Encoding::UTF_8) }[int - 1]
  end

  def price_fields(index, hyogo_price_bucket_price_form)
    price_types = %w[large small eggy damaged large_shells small_shells thin_shells
                     small_triploid_shells triploid_shells large_triploid_shells]
    content_tag :div do
      price_types.map do |price_type|
        concat(
          price_field(index, hyogo_price_bucket_price_form, price_type)
        )
      end
    end
  end

  def price_field(index, hyogo_price_bucket_price_form, price_type)
    content_tag(:div, class: 'input-group input-group-sm mb-1') do
      concat price_field_label(index, price_type)
      concat hyogo_price_bucket_price_form.text_field(price_type, class: 'form-control', type: 'number')
    end
  end

  def price_field_label(index, price_type)
    data_action = if index.positive?
      { action: 'click->oyster-supplies--supply-price-actions#copyPrice',
        controller: 'tippy',
        tippy_content: '<center>クリックしたら一番前の同じ種類の単価をここにコピーします</center>' }
                  else
      {}
                  end
    content_tag(:span,
                type_to_japanese(price_type),
                class: "input-group-text p-1 no-select #{'cursor-pointer' if index.positive?}",
                style: 'font-size: 0.75rem;',
                data: {
                  **data_action,
                  price_type: price_type
                })
  end

  def invoice_preview_link(icon, invoice_format, layout, location)
    link_to icon(icon),
            invoice_preview_path(
              invoice_format: invoice_format,
              layout: layout,
              start_date: @start_date,
              end_date: @end_date,
              location: location
            ),
            class: "btn btn-light ms-2 tippy #{'opacity-25' unless layout == 2}",
            data: {
              controller: 'tippy',
              tippy_content: invoice_preview_tippy_content(invoice_format, layout, location),
              turbo_prefetch: false
            }
  end

  def invoice_preview_tippy_content(invoice_format, layout, location)
    "#{section_to_japanese(location)}の#{invoice_format == 'supplier' ? '各生産者' : '生産者まとめ'}の<br>仕切りプレビューを作成<br>(#{layout == 2 ? '2023' : '2018'}形式)"
  end

  def translator(keys, values, string)
    rosetta = keys.map.with_index { |key, i| [key, values[i]] }.to_h
    return string unless rosetta.keys.include?(string)

    rosetta[string]
  end

  def types
    %w[large small eggy damaged large_shells small_shells thin_shells small_triploid_shells triploid_shells
       large_triploid_shells xl_triploid_shells]
  end

  def type_to_japanese(type)
    values = %w[むき身（大） むき身（小） むき身（卵） むき身（傷） 殻付き（大） 殻付き（小） 殻付き（バラ） 三倍体（M） 三倍体（L） 三倍体（LL） 三倍体（LLL）]
    translator(types, values, type)
  end

  def type_to_unit(type)
    values = %w[㎏ ㎏ ㎏ ㎏ 個 個 ㎏ 個 個 個]
    translator(types, values, type)
  end

  def kanji_am_pm(am_or_pm)
    keys = %w[am pm 午前 午後]
    values = %w[午前 午後 am pm]
    translator(keys, values, am_or_pm)
  end

  def print_price_title(type)
    values = %w[￥600~￥3000 ￥600~￥3000 ￥600~￥3000 ￥600~￥3000 ￥30~￥100 ￥30~￥100 ￥200~￥800 ¥50~¥200 ¥50~¥200 ¥50~¥200]
    translator(types, values, type)
  end

  def stat_column_title(stat)
    keys = %w[grand_total hyogo_grand_total sakoshi_subtotal aioi_subtotal okayama_grand_total kara_grand_total hoka_grand_total]
    values = %w[総合計 兵庫県合計 坂越小計 相生小計 岡山県合計 殻付き合計 その他合計]
    translator(keys, values, stat)
  end

  def get_supply_stat(stat, supply)
    return unless supply

    totals = supply.totals
    keys = %w[grand_total hyogo_grand_total sakoshi_subtotal aioi_subtotal okayama_grand_total kara_grand_total hoka_grand_total]
    values = [
      totals[:mukimi_total].to_i,
      totals[:hyogo_total].to_i,
      totals[:sakoshi_muki_volume].to_i,
      totals[:aioi_muki_volume].to_i,
      totals[:okayama_total].to_i,
      totals[:shell_total].to_i,
      totals[:other_total].to_i
    ]
    translator(keys, values, stat)
  end

  def get_supply_stat_details(stat, supply)
    return unless supply

    totals = supply.totals
    hyogo_large = totals[:sakoshi_large_volume] + totals[:aioi_large_volume]
    hyogo_small = totals[:sakoshi_small_volume] + totals[:aioi_small_volume]
    {
      'grand_total' => '・',
      'hyogo_grand_total' => "#{hyogo_large}・#{hyogo_small}",
      'sakoshi_subtotal' => "#{totals[:sakoshi_large_volume]}・#{totals[:sakoshi_small_volume]}",
      'aioi_subtotal' => "#{totals[:aioi_large_volume]}・#{totals[:aioi_small_volume]}",
      'okayama_grand_total' => '・',
      'kara_grand_total' => '・',
      'hoka_grand_total' => '・'
    }[stat]
  end

  def stat_hash(supplies)
    supplies.map { |supply| { date: supply.supply_date, data: supply.totals } }
  end

  def stat_key_to_japanese(key)
    conversion_hash = {
      okayama_total: '岡山県量合計(kg)',
      shell_total: '兵庫県殻付き合計(個)',
      big_shell_avg_cost: '兵庫県殻付き一個単価平均(¥)',
      sakoshi_damaged_volume: '坂越海域むきみ傷量(kg)',
      sakoshi_eggy_volume: '坂越海域むきみ卵量(kg)',
      sakoshi_small_volume: '坂越海域むきみ小量(kg)',
      sakoshi_large_volume: '坂越海域むきみ大量(kg)',
      sakoshi_muki_volume: '坂越全むき身量小計(kg)',
      aioi_damaged_volume: '相生海域むきみ傷量(kg)',
      aioi_eggy_volume: '相生海域むきみ卵量(kg)',
      aioi_small_volume: '相生海域むきみ小量(kg)',
      aioi_large_volume: '相生海域むきみ大量(kg)',
      aioi_muki_volume: '相生全むき身量小計(kg)',
      sakoshi_damaged_cost: '坂越海域むき身経費小計(¥)',
      sakoshi_eggy_cost: '坂越海域むき身卵経費小計(¥)',
      sakoshi_small_cost: '坂越海域むき身小経費小計(¥)',
      sakoshi_large_cost: '坂越海域むき身大経費小計(¥)',
      sakoshi_muki_cost: '坂越海域全むき身経費小計(¥)',
      sakoshi_avg_kilo: '坂越海域むき身キロ単価平均(¥)',
      aioi_damaged_cost: '相生海域むき身傷経費小計(¥)',
      aioi_eggy_cost: '相生海域むき身卵経費小計(¥)',
      aioi_small_cost: '相生海域むき身小経費小計(¥)',
      aioi_large_cost: '相生海域むき身大経費小計(¥)',
      aioi_muki_cost: '相生海域全むき身経費小計(¥)',
      aioi_avg_kilo: '相生海域むき身キロ単価平均(¥)',
      hyogo_total: '兵庫県むき身量合計(kg)',
      hyogo_mukimi_cost_total: '兵庫県むき身経費合計(¥)',
      hyogo_avg_kilo: '兵庫県むき身キロ単価平均(¥)',
      okayama_mukimi_cost_total: '岡山県むき身経費合計(¥)',
      okayama_avg_kilo: '岡山県むき身キロ単価平均(¥)',
      other_total: 'その他のむき身経費合計(kg)',
      other_cost_total: 'その他のむき身経費合計(¥)',
      other_avg_kilo: 'その他のむき身キロ単価平均(¥)',
      mukimi_total: '全むき身量合計(kg)',
      cost_total: '全むき身経費合計(¥)',
      total_kilo_avg: '全むき身キロ単価平均(¥)'
    }
    conversion_hash.include?(key) ? conversion_hash[key] : key
  end

  def section_to_japanese(section)
    keys = %w[sakoshi aioi okayama other]
    values = %w[坂越 相生 岡山 その他]
    translator(keys, values, section)
  end

  def number_date(supply_date)
    "d#{supply_date.scan(/\d+/).join}"
  end

  def stat_key_to_unit(key)
    stat_key_to_japanese(key)[/(?<=\().*(?=\))/]
  end

  def period_stats(stat_hash)
    stat_hash.each_with_object({}) do |supply, new_hash|
      supply[:data].each do |key, int|
        if key.to_s.include?('avg')
          if int.positive?
            new_hash[key].nil? ? new_hash[key] = [int] : new_hash[key] << int
          end
        else
          new_hash[key].nil? ? new_hash[key] = int : new_hash[key] += int
        end
      end
    end
  end

  def supply_title(supply)
    total = supply.totals[:mukimi_total].round(0)
    est_price = supply.totals[:total_kilo_avg].round(0)
    price = "@#{est_price}¥/㎏"
    show_price = current_user.admin? && supply.check_completion.empty?
    "#{total}㎏　#{price if show_price}"
  end

  def supply_input(*args)
    dig_point = args.dup
    input_value = @oyster_supply&.oysters&.dig(*args)
    input_value ||= 0
    time = args.include?('am') ? 'am' : 'pm'
    pm = args.include?('pm')
    subtotal = args.include?('subtotal')
    readonly = subtotal ? { readonly: 'readonly', disabled: 'disabled' } : {}
    name = args.pop

    inputs_html = {
      class: 'form-control form-control-sm mb-0 ',
      input_html: {
        class: "floatTextBox#{' bg-dark text-white' if pm && !subtotal}",
        value: input_value,
        type: 'number',
        data: {
          time: time,
          type: args[1],
          supplier: args[2],
          dig_point: dig_point,
          oyster_supplies__supply_channel_target: 'input'
        },
        **readonly
      }
    }

    recursive_field_for(@oysters_form, args, name, **inputs_html)
  end

  def recursive_field_for(form, args, name, **inputs_html)
    if args.empty?
      form.input name, type: 'number', label: false, **inputs_html
    else
      key = args.shift
      form.fields_for key do |nested_form|
        recursive_field_for(nested_form, args, name, **inputs_html)
      end
    end
  end

  def supply_description(supply)
    <<~HTML
      <div class='container-flex small'>
        <table class='table table-sm table-hover table-striped table-dark'>
          <thead>
            <tr>
              <th scope='col'>場所</th>
              <th scope='col'>
                量
              </th>
              <th scope='col'>単価(¥/㎏)</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th scope='row'>兵庫</th>
              <td>
                #{supply.totals[:hyogo_total].round(0)}㎏<br>
                ( 大#{supply.hyogo_large_shucked_total.round(0)}㎏ / 小#{supply.hyogo_small_shucked_total.round(0)}㎏)
              </td>
              <td>@#{supply.totals[:hyogo_avg_kilo].round(0)}㎏</td>
            </tr>
            <tr>
              <th scope='row'>坂越</th>
              <td>
                #{supply.totals[:sakoshi_muki_volume].round(0)}㎏<br>
                ( 大#{supply.totals[:sakoshi_large_volume].round(0)}㎏ / 小#{supply.totals[:sakoshi_small_volume].round(0)}㎏)
              </td>
              <td>@#{supply.totals[:sakoshi_avg_kilo].round(0)}㎏</td>
            </tr>
            <tr>
              <th scope='row'>相生</th>
              <td>
                #{supply.totals[:aioi_muki_volume].round(0)}㎏<br>
                ( 大#{supply.totals[:aioi_large_volume].round(0)}㎏ / 小#{supply.totals[:aioi_small_volume].round(0)}㎏)
              </td>
              <td>@#{supply.totals[:aioi_avg_kilo].round(0)}㎏</td>
            </tr>
            <tr>
              <th scope='row'>岡山</th>
              <td>#{supply.totals[:okayama_total].round(0)}㎏</td>
              <td>@#{supply.totals[:okayama_avg_kilo].round(0)}</td>
            </tr>
            <tr>
              <th scope='row'>その他</th>
              <td>#{supply.totals[:other_total]&.round(0)}㎏</td>
              <td>@#{supply.totals[:other_avg_kilo]&.round(0)}</td>
            </tr>
            <tr>
              <th scope='row'>殻付</th>
              <td>#{supply.totals[:shell_total].round(0)}個 / #{supply.hyogo_thin_shells_total.round(0)}㎏</td>
              <td>@#{supply.totals[:big_shell_avg_cost].round(0)}</td>
            </tr>
            <tr>
              <th scope='row'>合計</th>
              <td>#{supply.totals[:mukimi_total].round(0)}㎏</td>
              <td>@#{supply.totals[:total_kilo_avg].round(0)}㎏</td>
            </tr>
          </tbody>
        </table>
      </div>
    HTML
  end
end
