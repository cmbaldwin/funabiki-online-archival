module Oroshi::SupplyDateHelper
  def frame_id(*args)
    args.map { |arg| dom_id(arg) }.join('_')
  end

  def select_supplies(supplier, supply_type_variation)
    @supplies.select do |supply|
      next unless supply

      supply.supplier == supplier &&
        supply.supply_type_variation == supply_type_variation &&
        supply.supply_date == @supply_date &&
        supply.supply_reception_time == @supply_reception_time
    end
  end

  def supply_type_variations
    supply_type_variations = @supplier_organization.suppliers.map(&:supply_type_variations).flatten.uniq
    grouped_variations = supply_type_variations.group_by(&:supply_type)

    grouped_variations.sort_by do |supply_type, variations|
      [-variations.length, supply_type.name]
    end.to_h
  end
end
