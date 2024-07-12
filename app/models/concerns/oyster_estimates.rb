# app/models/concerns/oyster_estimates.rb

# This creates informal associations between OysterSupply and Profit models
# It also creates methods to calculate estimates for the day's oyster sales
module OysterEstimates
  extend ActiveSupport::Concern
  included do
    def shared_profits
      return unless holiday? || day_before_holiday? || !associated_supplies.compact.empty?

      Profit.where(date: associated_supplies.compact.map(&:date))
    end

    # If the Profit is a holiday, find and include OysterSupplies from both the two days prior
    # If the day prior includes Sakoshi, Aioi, or Mushiage oysters, then exclude
    # If the Profit isn't a holiday, check for an OysterSupply for that day, if that OysterSupply
    # includes Sakoshi, Aioi, or Mushiage oysters, then include that day in the days calculations
    # Otherwise include the OysterSupply for the day before
    def associated_supplies
      return @associated_supplies if @associated_supplies

      @associated_supplies ||= if holiday?
                                 holiday_supplies
                               elsif day_before_holiday?
                                 return [yesterday_supply] unless this_date_supply

                                 odd_oyster_supply?(this_date_supply) ? [this_date_supply] : [yesterday_supply]
                               else
                                find_supply
                               end.compact
    end

    def associated_supplies_complete?
      return true if associated_supplies.compact.empty?

      # Supply is complete if check_completion is empty
      associated_supplies.map { |supply| supply.check_completion.empty? }.all?
    end

    def combined_total(key)
      return 0 if associated_supplies.compact.empty?

      associated_supplies.map { |supply| supply.totals[key].to_f }.sum.round(2)
    end

    def combined_average(key)
      return 0 if associated_supplies.compact.empty?

      associated_supplies.map { |supply| supply.totals.fetch(key, 0) }.sum.round(2) / associated_supplies.count
    end

    def combined_okayama_total(locale)
      return 0 if associated_supplies.compact.empty?

      associated_supplies.map { |supply| supply.oysters['okayama'][locale]['subtotal'].to_f }.sum.round(2)
    end

    def ichiba_holidays
      return @ichiba_holidays if @ichiba_holidays

      @ichiba_holidays ||= BrowseBot.new.ichiba_holidays(Time.zone.today.year)
    end

    def holiday?
      ichiba_holidays.include?(date)
    end

    def day_before_holiday?
      ichiba_holidays.map { |holiday| holiday - 1.day }.include?(date)
    end

    def odd_oyster_supply?(supply)
      supply&.totals&.[](:hyogo_total)&.positive? || supply&.mushiage_total&.positive?
    end

    def prior_two_day_supplies
      return @prior_two_day_supplies if @prior_two_day_supplies

      @prior_two_day_supplies ||= OysterSupply.where(date: (date - 2.days)..(date - 1.day))
    end

    def yesterday_supply
      return @yesterday_supply if @yesterday_supply

      @yesterday_supply ||= OysterSupply.find_by(date: date - 1.day)
    end

    def this_date_supply
      return @this_date_supply if @this_date_supply

      @this_date_supply ||= OysterSupply.find_by(date: date)
    end

    def find_supply
      supplies = [yesterday_supply, this_date_supply]
      prior_profit = Profit.where(date: date - 1.day).first
      # If the profit for the day before this one was irregular, include both supplies, else compact.first
      return supplies if prior_profit&.irregular_holiday

      [supplies.compact.first]
    end

    def irregular_holiday
      # If the day before has no Profit, like at the start of the season or start of the year,
      # farmers will shuck oysters, so irregular rules apply
      Profit.where(date: date - 1.day).empty?
    end

    def holiday_supplies
      return [this_date_supply] if irregular_holiday

      prior_two_day_supplies.reject { |supply| (supply.date == date - 1.day) && odd_oyster_supply?(supply) }
    end
  end
end
