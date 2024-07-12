# frozen_string_literal: true

class Invoice
  # Oyster Supply Iterating Module - Mixin for Supplier Invoice PDF generator
  module SupplyIterators
    private

    def daily_subtotals
      supplies.each do |supply|
        iterate_types(supply)
      end
    end

    def range_totals(date)
      @range_total ||= []
      @range_total << daily_total(date)
      @range_tax ||= []
      @range_tax << (daily_total(date) * 0.08)
    end

    def iterate_types(supply)
      @types.each do |type|
        accumulate_subtotals(supply, type)
      end
    end

    def accumulate_subtotals(supply, type)
      return unless supply.oysters[type]

      supply.oysters[type].each do |supplier, values|
        next unless supply_inclusion_check(supplier, values)

        date = supply.supply_date
        init_subtotals(date, type)
        %w[volume invoice].each do |key|
          entry_point = @subtotals[date][type]
          add_subtotal_value(entry_point, values, key)
          add_total_value(type, values, key)
        end
      end
    end

    def supply_inclusion_check(supplier, values)
      return false unless values['volume'].to_f.positive?

      if @current_supplier
        supplier == @current_supplier.id.to_s
      else
        supplier_numbers.include?(supplier)
      end
    end

    def init_subtotals(date, type)
      @subtotals ||= {}
      @subtotals[date] ||= {}
      @subtotals[date][type] ||= {}
    end

    def add_subtotal_value(entry_point, values, key)
      entry_point[values['price']] ||= {}
      entry_point[values['price']][key] ||= 0
      entry_point[values['price']][key] += values[key].to_f
    end

    def add_total_value(type, values, key)
      @totals ||= {}
      @totals[type] ||= {}
      @totals[type][key] ||= 0
      @totals[type][key] += values[key].to_f
    end
  end
end
