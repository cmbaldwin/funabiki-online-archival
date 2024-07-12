# app/models/concerns/data_mutator.rb
module StatMutator
  extend ActiveSupport::Concern

  included do
    def prior_stat
      @prior_stat ||= Stat.get_prior_season_end
      @prior_stat
    end

    def total_profit_estimate_chart_data_data
      transform_date_keys(
        create_chart_data(
          data&.fetch(:total_profit_estimate_chart_data, {}),
          data&.fetch(:prior_season_total_profit_estimate_chart_data, {}),
          prior_stat&.data&.fetch(:prior_season_total_profit_estimate_chart_data, {})
        ),
        :values_by_10k
      )
    end

    def market_profit_chart_data_data
      transform_date_keys(
        create_chart_data(
          data&.fetch(:market_profit_chart_data, {}),
          data&.fetch(:prior_season_market_profit_chart_data, {}),
          prior_stat&.data&.fetch(:prior_season_market_profit_chart_data, {})
        ),
        :to_week_number
      )
    end

    def oyster_sales_kilo_price_chart_data
      transform_date_keys(
        create_chart_data(
          data&.fetch(:kilo_sales_estimate_chart_data, {}),
          data&.fetch(:prior_season_kilo_sales_estimate_chart_data, {}),
          prior_stat&.data&.fetch(:prior_season_kilo_sales_estimate_chart_data, {})
        ),
        :to_week_number_with_average
      )
    end

    def oyster_market_kilo_price_chart_data
      transform_date_keys(
        create_chart_data(
          data&.fetch(:farmer_kilo_costs_chart_data, {}),
          data&.fetch(:prior_season_farmer_kilo_costs_chart_data, {}),
          prior_stat&.data&.fetch(:prior_season_farmer_kilo_costs_chart_data, {})
        ),
        :to_week_number_with_average
      )
    end

    def oyster_volume_chart_data
      transform_date_keys(
        create_chart_data(
          data&.fetch(:oyster_supply_volumes_chart_data, {}),
          data&.fetch(:prior_season_oyster_supply_volumes_chart_data, {}),
          prior_stat&.data&.fetch(:prior_season_oyster_supply_volumes_chart_data, {})
        ),
        :to_week_number_with_average
      )
    end

    def order_count_chart_data
      ensure_date_replication(
        create_chart_data(
          order_count_by_week,
          order_count_by_week(prior: true),
          prior_stat.order_count_by_week(prior: true)
        )
      )
    end

    def order_count_by_week(prior: false)
      key = "#{prior ? 'prior_season_' : ''}all_online_order_count_data".to_sym
      online_shop_value_accumulator(data&.fetch(key, {}))
    end

    def order_sales_chart_data
      ensure_date_replication(
        create_chart_data(
          order_sales_by_week,
          order_sales_by_week(prior: true),
          prior_stat.order_sales_by_week(prior: true)
        )
      )
    end

    def order_sales_by_week(prior: false)
      key = "#{prior ? 'prior_season_' : ''}all_online_shop_sales_data".to_sym
      online_shop_value_accumulator(data&.fetch(key, {}))
    end

    def furusato_order_count_chart_data
      transform_date_keys(
        create_chart_data(
          data&.fetch(:furusato_count_data, {}),
          data&.fetch(:prior_season_furusato_count_data, {}),
          prior_stat.data&.fetch(:prior_season_furusato_count_data, {})
        ),
        :to_week_number
      )
    end

    private

    def create_chart_data(data_one, data_two, data_three)
      [
        { name: this_season_string,
          data: data_one },
        { name: prior_season_string,
          data: data_two },
        { name: two_seasons_prior_string,
          data: data_three }
      ]
    end

    def this_season_string
      "#{season_start.year} ~ #{season_end.year}"
    end

    def prior_season_string
      "#{prior_season_start.year} ~ #{prior_season_end.year}"
    end

    def two_seasons_prior_string
      "#{prior_stat.prior_season_start.year} ~ #{prior_stat.prior_season_end.year}"
    end

    def ensure_date_replication(hash)
      # Get all the keys from all the subhashes, only if the value is not zero and remove duplicates
      all_keys = hash.map { |subhash| subhash[:data].map { |k, v| k unless v.zero? }.compact }.flatten.uniq

      # Create a new array of subhashes with the same keys and sort them
      hash.map do |subhash|
        {
          name: subhash[:name],
          data: all_keys.map { |key| [key, subhash[:data][key] || 0] }.sort.to_h
        }
      end
    end

    def online_shop_value_accumulator(hash)
      hash.each_with_object({}) do |(shop, orders), result|
        # Skip furusato orders because we stopped recording it last year
        next if shop == :furusato_orders

        orders.each do |date, count|
          month_and_week_number = month_and_week_number(date)
          result[month_and_week_number] ||= 0
          result[month_and_week_number] += count
        end
      end
    end

    def transform_date_keys(data, method)
      ensure_date_replication(data.map do |data_hash|
        data_hash[:data] = send(method, data_hash[:data])
        data_hash
      end)
    end

    def values_by_10k(data)
      data.each_with_object({}) do |(date, value), result|
        next if value.zero?

        result[date] = value / 10000
      end
    end

    def to_week_number(data)
      data.each_with_object({}) do |(date, value), result|
        next if value.zero?

        month_and_week_number = month_and_week_number(date)
        result[month_and_week_number] = result.fetch(month_and_week_number, 0) + value
      end
    end

    def to_week_number_with_average(data)
      week_counts = {}
      new_data = data.each_with_object({}) do |(date, value), result|
        next if value.zero?

        month_and_week_number = month_and_week_number(date)
        result[month_and_week_number] = result.fetch(month_and_week_number, 0) + value
        week_counts[month_and_week_number] = week_counts.fetch(month_and_week_number, 0) + 1
      end
      new_data.each { |key, value| new_data[key] = value.to_f / week_counts[key] }
      new_data
    end

    def month_and_week_number(date)
      week_number = date.strftime('%U').to_i
      "#{I18n.l(date, format: '%B')} 第#{week_number}週"
    end
  end
end
