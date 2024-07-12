class OysterSupplyCheck
  # Header and Footer module
  module SupplyTable
    def supply_table
      [
        *supply_constructor
      ]
    end

    private

    def supply_constructor
      [
        supply_table_header,
        *supplier_constructor
      ]
    end

    def supply_table_header
      ['海域', '生産者', '数量(kg)', 'セル数', '官能検査', '温度(℃)', 'pH', '塩分(%)', '最終判定', '確認者']
    end

    def supplier_constructor
      [@sakoshi_suppliers, @aioi_suppliers].each_with_object([]) do |suppliers_by_location, memo|
        @current_suppliers = suppliers_by_location
        @types.each { |type| instance_variable_set("@#{type}_total", 0) }
        accumulate_supply_totals(@current_suppliers)
        @current_suppliers.each_with_index do |supplier, idx|
          @current_supplier = supplier
          accumulate_supplier_data(idx, memo)
        end
      end
    end

    def accumulate_supply_totals(suppliers)
      suppliers.each do |supplier|
        accumulate_type_values(supplier, 'total')
      end
    end

    def accumulate_type_values(supplier, str)
      @types.each do |type|
        reset_variables(type, str)
        dig_point = [@current_receiving_time, type, supplier.id.to_s]
        value = @supply.oysters.dig(*dig_point).values.map(&:to_f).sum
        instance_variable_set("@#{type}_#{str}", instance_variable_get("@#{type}_#{str}") + value.to_f)
      end
    end

    def accumulate_supplier_data(idx, memo)
      accumulate_supplier_subtotals
      memo << supplier_header(idx)
      memo << supplier_content
    end

    def reset_variables(type, str)
      supplier_subtotal = str == 'subtotal'
      variable_intitialization = instance_variable_get("@#{type}_#{str}").nil?
      return unless supplier_subtotal || variable_intitialization

      instance_variable_set("@#{type}_#{str}", 0)
    end

    def accumulate_supplier_subtotals
      accumulate_type_values(@current_supplier, 'subtotal')
    end

    def supplier_total
      @types.map { |type| instance_variable_get("@#{type}_subtotal") }.sum
    end

    def supplier_shucked_total
      %w[large small eggy damaged].map { |type| instance_variable_get("@#{type}_subtotal") }.sum
    end

    def supplier_shell_total
      %w[large_shells small_shells thin_shells small_triploid_shells triploid_shells large_triploid_shells xl_triploid_shells]
        .map { |type| instance_variable_get("@#{type}_subtotal") }.sum
    end

    def supplier_header(idx)
      [
        local_left_header(idx),
        { content: @supply.number_to_circular(@current_supplier.supplier_number.to_s), size: 11, align: :center,
          background_color: (supplier_total.zero? ? 'cfcfcf' : 'ffffff') },
        { content: "<font size='7'>合計  </font><b>#{supplier_shucked_total.zero? ? 'なし' : supplier_shucked_total}<b>",
          size: 9 },
        { content: (supplier_shell_total.zero? ? 'なし' : shell_text('subtotal').squish), size: 7, padding: 1, valign: :center, align: :center },
        *empty_check_cells
      ].compact
    end

    def local_left_header(idx)
      return unless idx.zero?

      { content: local_header_content, rowspan: (@current_suppliers.length * 2),
        valign: :top, align: :center }
    end

    def local_header_content
      <<~HEADER
        <font size='20'>#{@current_supplier.location.chars.join('<br>')}</font><br>
        <font size='12'>大</font>
        <font size='9'>#{@large_total}</font>
        <font size='12'>小</font>
        <font size='9'>#{@small_total}</font>
        <font size='12'>セル</font>
        <font size='9'>#{shell_text('total')}</font>
      HEADER
    end

    def no_shucked_content(str)
      if supplier_shucked_total.zero?
        { content: '／', align: :center, size: 12 }
      else
        { content: str, align: :right, size: 7 }
      end
    end

    def empty_check_cells
      [
        '',
        no_shucked_content('℃'),
        no_shucked_content(''),
        no_shucked_content('%'),
        '',
        ''
      ]
    end

    def current_supplier_total
      %w[large small eggy damaged].map { |type| instance_variable_get("@#{type}_subtotal") }.sum
    end

    def sum_vars(types, str)
      types.map { |type| instance_variable_get("@#{type}_#{str}") }.sum
    end

    def shell_text(str)
      countable_shells = sum_vars(%w[large_shells small_shells], str)
      weighable_shells = sum_vars(%w[thin_shells], str)
      triploid_shells = sum_vars(%w[small_triploid_shells triploid_shells large_triploid_shells xl_triploid_shells], str)
      [("#{countable_shells.to_i}個 " if countable_shells.positive?),
       ("#{weighable_shells.to_i}kg" if weighable_shells.positive?),
       ("三倍体#{triploid_shells.to_i}個" if triploid_shells.positive?)].compact.join('／')
    end

    def bucket_suffix(type)
      {
        'large' => '',
        'small' => '(小)',
        'eggy' => '(卵)',
        'damaged' => '(傷)'
      }[type]
    end

    def accumulate_buckets(type)
      dig_point = [@current_receiving_time, type, @current_supplier.id.to_s]
      buckets = @supply.oysters.dig(*dig_point)&.except('subtotal')&.values&.compact_blank
      buckets&.map { |bucket| "#{bucket}#{bucket_suffix(type)}" if bucket.to_f.positive? }
    end

    def supplier_content
      [
        { content: @current_supplier.nickname, size: 7, align: :center, padding: 1, font: 'TakaoPMincho',
          background_color: (supplier_total.zero? ? 'cfcfcf' : 'ffffff') },
        { content: "#{print_buckets} ", colspan: 6, size: 8, padding: 2, valign: :top, font_style: :light },
        { content: ':数量小計/備考', colspan: 1, size: 6, padding: 1, align: :right, valign: :center },
        ''
      ]
    end

    def print_buckets
      %w[large small eggy damaged].map { |type| accumulate_buckets(type) }.flatten.compact_blank.join('   ')
    end
  end
end
