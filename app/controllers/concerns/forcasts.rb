module Forcasts
  extend ActiveSupport::Concern

  def accumulate_forcast_data
    @models.each_with_object({}) do |model, memo|
      memo[model] ||= Set.new
      @range.each { |date| iterate_orders(date, model, memo) }
    end
  end

  def iterate_orders(date, model, memo)
    orders = model.classify.constantize.with_date(date)
    init_accumulator(model, memo, date)
    orders.each do |order|
      accumulate_items(model, order, date, memo)
    end
  end

  def init_accumulator(model, memo, date)
    memo[:orders] ||= Set.new
    memo[date] ||= {}
    memo[date][:orders] ||= Set.new
    memo[date][model] ||= {}
    memo[date][model][:orders] ||= Set.new
  end

  def accumulate_items(model, order, date, memo)
    order.item_ids_counts.each do |item_id, count|
      products = EcProduct.with_reference_id(item_id)
      products.each do |product|
        @types.each do |type_array|
          next unless type_array.include?(product.ec_product_type.name)

          add_order_to_set(memo, model, date, order.id)
          add_counts(memo[date], model, type_array[0], product.quantity.to_i, count)
        end
      end
    end
  end

  def add_order_to_set(memo, model, date, order_id)
    memo[:orders] << order_id
    memo[model] << order_id
    memo[date][:orders] << order_id
    memo[date][model][:orders] << order_id
  end

  def add_counts(entry_point, model, type, quantity, count)
    entry_point[model][type] ||= 0
    entry_point[type] ||= 0
    entry_point[type] += (quantity * count)
    entry_point[model][type] += (quantity * count)
  end

  def fetch_forcast_tippy_data(date)
    @stat = Stat.find_by(date: date)

    if @stat
      @counts = @stat.print_seperated_orders.join('件<br>')
    else
      orders = {}
      [RakutenOrder, YahooOrder, OnlineOrder, FurusatoOrder, InfomartOrder].each do |model|
        orders[model] = model.with_date([date])
      end
      @counts = orders.map { |model, list| "#{model.first.model_name.human}: #{list.length}" }.join('件<br>')
    end

    @last_year_date = (date - 1.year)
    @last_year_stat = Stat.find_by(date: @last_year_date)
    if !@last_year_stat || @last_year_stat.data.nil?
      @last_year_stat ||= Stat.new(date: @last_year_date)
      @last_year_stat.set_data
      @last_year_stat.save
      @last_year_stat.reload
    end
    @last_year_count = @last_year_stat.self_count

    weekday = date.strftime('%A').downcase.to_sym
    @last_year_weekday_date = (date - 1.year).prev_occurring(weekday)
    @last_year_weekday_stat = Stat.find_by(date: @last_year_weekday_date)
    if !@last_year_weekday_stat || @last_year_weekday_stat.data.nil?
      @last_year_weekday_stat ||= Stat.new(date: @last_year_date)
      @last_year_weekday_stat.set_data
      @last_year_weekday_stat.save
      @last_year_weekday_stat.reload
    end
    @last_year_weekday_count = @last_year_weekday_stat.self_count

    respond_to do |format|
      format.html { render layout: false }
    end
  end
end
