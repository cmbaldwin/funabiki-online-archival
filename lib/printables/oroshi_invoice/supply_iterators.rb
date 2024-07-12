# frozen_string_literal: true

class OroshiInvoice
  # Oyster Supply Iterating Module - Mixin for Supplier Invoice PDF generator
  module SupplyIterators
    private

    def prepare_invoice_rows
      daily_subtotals
      return unless @subtotals.any? && @layout == 2

      @invoice_subtotal = 0
      @invoice_rows = @subtotals.each_with_object([]) do |(date, subtotals), rows|
        subtotals.sort.each do |supply_type_variation, prices|
          prices.sort.each do |price, volume|
            subtotal = price * volume
            @invoice_subtotal += subtotal
            rows << invoice_row(date, supply_type_variation, price, volume, subtotal)
          end
        end
      end
      @tax_subtotal = @invoice_subtotal * 0.08
    end

    def invoice_row(date, supply_type_variation, price, volume, subtotal)
      [l(date, format: :short),
       { content: "#{supply_type_variation}  ※", colspan: 2 },
       { content: "#{volume} #{supply_type_variation.units}", align: :center },
       { content: en_it(price.to_i, unit: ''), align: :center },
       { content: en_it(subtotal), align: :right }]
    end

    def daily_subtotals
      # to produce a hash like this:
      # { date => { supply_type_variation => { price => { volume: float } } } }
      @subtotals = {}
      current_supplies.each do |supply|
        date = supply.supply_date.date
        supply_type_variation = supply.supply_type_variation
        price = supply.price
        volume = supply.quantity
        accumulate_subtotals(date, supply_type_variation, price, volume)
        add_total_value(supply_type_variation, price, volume)
      end
    end

    def current_supplies
      return organization_supplies unless @current_supplier

      supplies.select { |supply| supply.supplier == @current_supplier }
    end

    def organization_supplies
      supplies.select { |supply| supply.supplier_organization == @supplier_organization }
    end

    def accumulate_subtotals(date, supply_type_variation, price, volume)
      @subtotals[date] ||= {}
      @subtotals[date][supply_type_variation] ||= {}
      @subtotals[date][supply_type_variation][price] ||= 0
      @subtotals[date][supply_type_variation][price] += volume
    end

    def add_total_value(supply_type_variation, price, volume)
      @totals ||= {}
      @totals[supply_type_variation] ||= {}
      @totals[supply_type_variation]['volume'] ||= 0
      @totals[supply_type_variation]['invoice'] ||= 0
      @totals[supply_type_variation]['volume'] += volume
      @totals[supply_type_variation]['invoice'] += price * volume
    end
  end
end
