# app/controllers/concerns/supply_price_assignment.rb
module SupplyPriceAssignment
  extend ActiveSupport::Concern

  # Form result params for `supply_prices_params['[prices]']` looks like:
  # {
  #   "1" => {  <-- supplier_organization_id
  #       "0" => { <-- basket_id
  #            "supplier_ids" =>
  #               [0] "",
  #               [1] "1",
  #               [2] "3"
  #           ],
  #           "basket_prices" => {
  #               "1" => "50",
  #               "2" => "1200",
  #               "3" => "900"
  #           }
  #       },

  def process_price_assignments
    @results = {}
    supply_prices_params['[prices]'].each do |supplier_organization_id, baskets|
      @current_organization = supplier_organization_id
      process_baskets(baskets)
    end
  end

  def process_baskets(baskets)
    baskets.each_value do |basket_hash|
      supplier_ids = basket_hash['supplier_ids'].compact_blank
      basket_prices = basket_hash['basket_prices']
      next if supplier_ids.empty? || basket_prices.values.map(&:to_f).sum.zero?

      process_supply_prices(supplier_ids, basket_prices)
    end
  end

  def process_supply_prices(supplier_ids, basket_prices)
    @supplies ||= Oroshi::Supply.includes(:supplier, :supply_type_variation)
                                .where(supply_date: @supply_dates.pluck(:id))
                                .where('quantity > 0').to_a
    basket_prices.each do |supply_type_variation_id, price|
      next if price.to_f.zero?

      supply_type_variation_info(supply_type_variation_id)
      update_supplies(supplier_ids, supply_type_variation_id, price)
    end
  end

  def supply_type_variation_info(supply_type_variation_id)
    @supply_type_variations ||= {}
    @supply_types ||= {}

    current_supply_type_variation = fetch_or_cache_record(@supply_type_variations, supply_type_variation_id) do
      Oroshi::SupplyTypeVariation.find(supply_type_variation_id)
    end

    current_supply_type = fetch_or_cache_record(@supply_types, current_supply_type_variation.supply_type_id) do
      current_supply_type_variation.supply_type
    end

    @current_supply_type_variation_name = current_supply_type_variation.to_s
    @current_supply_type_variation_units = current_supply_type.units
  end

  def fetch_or_cache_record(hash, key, &block)
    return hash[key] if hash[key]

    value = block.call
    hash[key] = value
    value
  end

  def update_supplies(supplier_ids, supply_type_variation_id, price)
    supplies = @supplies.select do |supply|
      supplier_ids.include?(supply.supplier_id.to_s) &&
        supply.supply_type_variation_id.to_s == supply_type_variation_id
    end
    supplies.each do |supply|
      record_result(supply, price) if supply.update_column(:price, price.to_f)
    end
  end

  def record_result(supply, price)
    supply_date = @supply_dates.find { |sd| sd.id == supply.supply_date_id }
    supply_date_date = l(supply_date.date, format: :long)
    @suppliers ||= {}
    supplier = fetch_or_cache_record(@suppliers, supply.supplier_id) { supply.supplier }
    supplier_name = supplier.company_name

    supply_type_results = init_results_hash(supply_date_date, supplier_name, price)
    supply_type_results[0] += supply.quantity
  end

  def init_results_hash(supply_date_date, supplier_name, price)
    org_results = @results[@current_organization] ||= {}
    date_results = org_results[supply_date_date] ||= {}
    supplier_results = date_results[supplier_name] ||= {}
    init_array = [0, price, @current_supply_type_variation_units]
    supplier_results[@current_supply_type_variation_name] ||= init_array
  end
end
