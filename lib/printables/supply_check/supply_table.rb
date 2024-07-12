class SupplyCheck
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
      ['海域', '生産者', '官能検査', '温度(℃)', 'pH', '塩分(%)', '最終判定', '時間・署名']
    end

    def supplier_constructor
      @supplier_organizations.each_with_object([]) do |supplier_organization, table|
        @current_supplier_organization = supplier_organization
        @current_suppliers = supplier_organization.suppliers.active.sort_by(&:supplier_number)
        accumulate_supply_totals(@current_suppliers)
        @current_suppliers.each_with_index do |supplier, idx|
          @current_supplier = supplier
          @current_supplies = @supply_date.supplies.where(supplier: supplier, supply_reception_time: @current_supply_reception_time)
          accumulate_supplier_data(idx, table)
        end
      end
    end

    def accumulate_supply_totals(suppliers)
      @supply_type_variations ||= @current_suppliers.map(&:supply_type_variations).flatten.uniq
      @supply_type_variations.each { |variation| instance_variable_set("@#{variation.to_var}_total", 0) }
      suppliers.each do |supplier|
        accumulate_type_values(supplier, 'total')
      end
    end

    def accumulate_type_values(supplier, str)
      @supply_type_variations.each do |variation|
        reset_variables(variation, str)
        value = @supply_date.supplies.where(supply_reception_time: @current_supply_reception_time, supplier: supplier, supply_type_variation: variation).sum(:quantity)
        instance_variable_set("@#{variation.to_var}_#{str}", instance_variable_get("@#{variation.to_var}_#{str}") + value.to_f)
      end
    end

    def reset_variables(record, str)
      supplier_subtotal = str == 'subtotal'
      variable_intitialization = instance_variable_get("@#{record.to_var}_#{str}").nil?
      return unless supplier_subtotal || variable_intitialization

      instance_variable_set("@#{record.to_var}_#{str}", 0)
    end

    def accumulate_supplier_data(idx, table)
      accumulate_type_values(@current_supplier, 'subtotal')
      table << supplier_header(idx)
      table << supplier_content
    end

    # { content: @current_supplier.invoice_name, size: 7, align: :center, padding: 1, font: 'TakaoPMincho', **cell_bg }
    def supplier_header(idx)
      [
        local_left_header(idx),
        { content: "<font size='12'>#{@current_supplier.circled_number}</font>
                    <font size='8'>#{@current_supplier.short_name}</font>",
          font: 'TakaoPMincho', padding: 1, rowspan: 2, align: :center, valign: :center, **cell_bg },
        *check_cells,
        signing_area(idx)
      ].compact
    end

    def local_left_header(idx)
      return unless idx.zero?

      { content: local_header_content, rowspan: (@current_suppliers.length * 2),
        valign: :top, align: :center }
    end

    def signing_area(idx)
      return unless idx.zero?

      { content: '', rowspan: (@current_suppliers.length * 2) }
    end

    def local_header_content
      <<~HEADER
        <font size='18'>#{@current_supplier_organization.micro_region.chars.join('<br>')}</font><br>
        #{print_micro_region_totals}
      HEADER
    end

    def print_micro_region_totals
      return if @current_suppliers.length < 2

      @supply_date.supply_type_variations.sort.map do |variation|
        total = instance_variable_get("@#{variation.to_var}_total")
        next unless total&.positive?

        "<font size='6'>#{variation}</font>
        <font size='8'>#{instance_variable_get("@#{variation.to_var}_total")}#{variation.units}</font>"
      end.compact.join('<br><br>')
    end

    def supplier_total
      @supply_type_variations.map { |variation| instance_variable_get("@#{variation.to_var}_subtotal") }.sum
    end

    def cell_bg(no_liquid_check_cell: false)
      return { background_color: 'cfcfcf' } if no_liquid_check_cell

      { background_color: (supplier_total.zero? ? 'cfcfcf' : 'ffffff') }
    end

    def check_cells
      [
        { content: '', **cell_bg },
        no_liquid_type('℃'),
        no_liquid_type(''),
        no_liquid_type('%'),
        { content: '', **cell_bg }
      ]
    end

    def no_liquid_type(str)
      if no_liquid_supplies?
        { content: '/', padding: 1, align: :center, size: 12, **cell_bg(no_liquid_check_cell: no_liquid_supplies?) }
      else
        { content: str, padding: 5, align: :right, size: 7, **cell_bg }
      end
    end

    def no_liquid_supplies?
      @supply_date.supplies.where(supplier: @current_supplier,
                                  supply_reception_time: @current_supply_reception_time,
                                  supply_type_variation: liquid_variations)
                  .sum(:quantity).zero?
    end

    def liquid_variations
      Oroshi::SupplyType.where(liquid: true).map(&:supply_type_variations).flatten
    end

    def supplier_content
      [
        { content: print_buckets, colspan: 5, leading: 4,
          size: 8, padding: 5, valign: :top, font_style: :light, **cell_bg }
      ]
    end

    def print_buckets
      @supply_type_variations.map { |variation| supply_type_variation_content(variation) }.compact.join('　・　')
    end

    def supply_type_variation_content(variation)
      return unless instance_variable_get("@#{variation.to_var}_subtotal").positive?

      quantities = @current_supplies.where(supply_type_variation: variation).map(&:quantity)
      quantities.reject! { |quantity| quantity <= 0 }
      return if quantities.empty?

      formatted_quantities = quantities.map { |quantity| (quantity % 1).zero? ? quantity.to_i : quantity }
      "#{variation}: #{formatted_quantities.join('  ')}"
    end
  end
end
