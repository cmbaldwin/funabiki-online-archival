class AnalysisController < ApplicationController
  before_action :check_status, only: %i[index]
  before_action :set_stats
  before_action :check_chart_data, only: %i[total_profit_estimate_analysis_chart market_profit_analysis_chart oyster_sales_kilo_price_analysis_chart oyster_market_kilo_price_analysis_chart oyster_volume_analysis_chart online_shop_order_count_chart online_shop_order_sales_chart furusato_order_count_chart]

  def check_status
    return if current_user.admin?

    flash[:notice] = 'そのページはアクセスできません。'
    redirect_to root_path, error: 'そのページはアクセスできません。'
  end

  def set_stats
    @stat = Stat.get_most_recent

    return if @stat.respond_to?(:data)

    head :no_content
  end

  def check_chart_data
    return if @stat.respond_to?(:data) && !@stat.try(:data).empty?

    render json: {}
  end

  def fetch_chart
    chart_params = Rack::Utils.parse_nested_query(params[:chart_params]).deep_symbolize_keys
    if chart_params[:init_params][:stacked]
      chart_params[:init_params][:stacked] =
        (chart_params[:init_params][:stacked] == 'true')
    end
    @chart_params = chart_params
    respond_to do |format|
      format.turbo_stream do
        render 'analysis/fetch_chart'
      end
    end
  end

  def index; end

  def total_profit_estimate_analysis_chart_partial
    @chart_params = {
      chart_type: 'line_chart',
      chart_path: 'total_profit_estimate_analysis_chart',
      init_params: {
        id: 'total_profit_estimate_chart',
        **chart_defaults('万￥'),
        **library_hash(
          "前シーズン1週間平均：#{@stat&.data&.[](:prior_season_total_profit_estimate_average)}　｜　今シーズン1週間平均：#{@stat&.data&.[](:this_season_total_profit_estimate_average)}"
        )
      }
    }

    render partial: 'chart_partial'
  end

  def total_profit_estimate_analysis_chart
    render json: current_user.admin? ? @stat.total_profit_estimate_chart_data_data : unauthorized_data
  end

  def market_profit_analysis_chart_partial
    @chart_params = {
      chart_type: 'line_chart',
      chart_path: 'market_profit_analysis_chart',
      init_params: {
        id: 'market_profit_analysis_chart',
        **chart_defaults('万￥'),
        **library_hash(
          "前シーズン1日平均：万#{@stat&.data&.[](:prior_season_market_profit_average)}　｜　今シーズン1日平均：万#{@stat&.data&.[](:this_season_market_profit_average)}"
        )
      }
    }

    render partial: 'chart_partial'
  end

  def market_profit_analysis_chart
    render json: current_user.admin? ? @stat.market_profit_chart_data_data : unauthorized_data
  end

  def oyster_sales_kilo_price_analysis_chart_partial
    @chart_params = {
      chart_type: 'line_chart',
      chart_path: 'oyster_sales_kilo_price_analysis_chart',
      init_params: {
        id: 'oyster_sales_kilo_price_analysis_chart',
        **chart_defaults('¥'),
        **library_hash(
          "前シーズン1日平均：#{@stat&.data&.[](:prior_season_kilo_sales_estimate_average)}　｜　今シーズン1日平均：#{@stat&.data&.[](:this_season_kilo_sales_estimate_average)}　｜　2年1日平均：#{@stat&.data&.[](:two_season_kilo_sales_estimate_average)}"
        )
      }
    }

    render partial: 'chart_partial'
  end

  def oyster_sales_kilo_price_analysis_chart
    render json: current_user.admin? ? @stat.oyster_sales_kilo_price_chart_data : unauthorized_data
  end

  def oyster_market_kilo_price_analysis_chart_partial
    @chart_params = {
      chart_type: 'line_chart',
      chart_path: 'oyster_market_kilo_price_analysis_chart',
      init_params: {
        **chart_defaults('¥'),
        **library_hash(
          "前シーズン1日平均：#{@stat&.data&.[](:prior_season_farmer_kilo_costs_average)}　｜　今シーズン1日平均：#{@stat&.data&.[](:this_season_farmer_kilo_costs_average)}　｜　2年1日平均：#{@stat&.data&.[](:two_season_farmer_kilo_costs_average)}"
        )
      }
    }
    render partial: 'chart_partial'
  end

  def oyster_market_kilo_price_analysis_chart
    render json: current_user.admin? ? @stat.oyster_market_kilo_price_chart_data : unauthorized_data
  end

  def oyster_volume_analysis_chart_partial
    @chart_params = {
      chart_type: 'line_chart',
      chart_path: 'oyster_volume_analysis_chart',
      init_params: {
        id: 'oyster_volume_analysis_chart',
        **chart_defaults('㎏'),
        **library_hash(
          "前シーズン1日平均：#{@stat&.data&.[](:prior_season_oyster_supply_volumes_average)}　｜　今シーズン1日平均：#{@stat&.data&.[](:this_season_oyster_supply_volumes_average)}　｜　2年1日平均：#{@stat&.data&.[](:two_season_oyster_supply_volumes_average)}"
        )
      }
    }
    render partial: 'chart_partial'
  end

  def oyster_volume_analysis_chart
    render json: current_user.admin? ? @stat.oyster_volume_chart_data : unauthorized_data
  end

  def online_shop_order_count_chart_partial
    data = @stat.data[:all_online_order_count_data]
    averages = data.each_with_object({}) do |item, memo|
      next if item[1].values.empty?

      memo[item[0]] = item[1].values.sum / item[1].values.length
    end
    total_average = averages.values.sum / averages.length

    @chart_params = {
      chart_type: 'line_chart',
      chart_path: 'online_shop_order_count_chart',
      init_params: {
        id: 'online_shop_order_count_chart',
        **chart_defaults('件'),
        **library_hash(
          averages.inject('') do |m, (k, v)|
            m += "#{shop_symbol_to_human(k)}一週間平均: #{v}件　｜　"
            m
          end + "全部の注文一週間平均:#{total_average}件"
        )
      }
    }
    render partial: 'chart_partial'
  end

  def online_shop_order_count_chart
    render json: @stat.order_count_chart_data
  end

  def online_shop_order_sales_chart_partial
    data = @stat.data[:all_online_shop_sales_data]
    weeks = data.values.map(&:length).max
    averages = data.transform_values { |hash| hash.values.sum / weeks }
    total_average = averages.values.sum

    @chart_params = {
      chart_type: 'line_chart',
      chart_path: 'online_shop_order_sales_chart',
      init_params: {
        id: 'online_shop_order_sales_chart',
        **chart_defaults('¥'),
        **library_hash(
          averages.inject('') do |m, (k, v)|
            m += "#{shop_symbol_to_human(k)}一週間平均: #{v}¥　｜　" unless v.to_i.zero?
            m
          end + "全部の注文一週間平均:#{total_average}¥"
        )
      }
    }
    render partial: 'chart_partial'
  end

  def online_shop_order_sales_chart
    render json: @stat.order_sales_chart_data
  end

  def furusato_order_count_chart_partial
    @chart_params = {
      chart_type: 'line_chart',
      chart_path: 'furusato_order_count_chart',
      init_params: {
        id: 'furusato_order_count_chart',
        **chart_defaults('件'),
        **library_hash("ふるさと納税注文数")
      }
    }
    render partial: 'chart_partial'
  end

  def furusato_order_count_chart
    render json: @stat.furusato_order_count_chart_data
  end

  private

  def chart_defaults(prefix)
    {
      loading: '読み込み中',
      thousands: ',',
      prefix: prefix,
      curve: true,
      min: 0
    }
  end

  def library_hash(title)
    {
      library: {
        elements: {
          point: {
            pointStyle: 'star',
            radius: 3
          }
        },
        plugins: {
          title: {
            display: true,
            padding: 5,
            font: {
              weight: 'bold',
              size: 12
            },
            text: title
          }
        }
      }
    }
  end

  def unauthorized_data
    [{ name: 'Unauthorized', data: {} }]
  end
end
