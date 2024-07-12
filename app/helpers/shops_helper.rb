module ShopsHelper
  def self.time_today
    Time.zone.today
  end

  def self.this_season_start
    Rails.cache.fetch('this_season_start', expires_in: 1.week) do
      time_today.month < 10 ? Date.new((time_today.year - 1), 10, 1) : Date.new(time_today.year, 10, 1)
    end
  end

  def self.this_season_end
    Rails.cache.fetch('this_season_end', expires_in: 1.week) do
      time_today.month < 10 ? Date.new(time_today.year, 9, 30) : Date.new((time_today.year + 1), 9, 30)
    end
  end

  def self.prior_season_start
    Rails.cache.fetch('prior_season_start', expires_in: 1.week) do
      time_today.month < 10 ? Date.new((time_today.year - 2), 10, 1) : Date.new((time_today.year - 1), 10, 1)
    end
  end

  def self.prior_season_end
    Rails.cache.fetch('prior_season_end', expires_in: 1.week) do
      time_today.month < 10 ? Date.new((time_today.year - 1), 9, 30) : Date.new(time_today.year, 9, 30)
    end
  end

  def forcast_counts
    item_ids_counts.each_with_object({}) do |(item_id, count), memo|
      products = EcProduct.with_reference_id(item_id)
      products.each do |product|
        forcast_countables.each do |type_array|
          next unless type_array.include?(product.ec_product_type.name)

          add_counts(memo, type_array[0], product.quantity.to_i, count)
        end
      end
    end
  end

  def forcast_countables
    [['殻付き', 'セット(殻付き)'], ['500g'], ['殻付き 小牡蠣'], ['三倍体 殻付き 牡蠣']]
  end

  def add_counts(memo, type, product, count)
    memo[type] ||= 0
    memo[type] += product.quantity.to_i * count.to_i
  end

  def shell_count
    accumulate_count(['殻付き', 'セット(殻付き)', 'セル（飲食店）'])
  end

  def triploid_count
    accumulate_count(['三倍体 殻付き 牡蠣'])
  end

  def bara_count
    accumulate_count(['殻付き 小牡蠣'])
  end

  def mukimi_count
    accumulate_count(['500g', '500g（飲食店）'])
  end

  def accumulate_count(type_names)
    item_ids_counts.map do |item_id, count|
      products = EcProduct.with_reference_id(item_id)
      products.map do |product|
        next unless type_names.any?(product.ec_product_type.name)

        product.quantity.to_i * count
      end
    end.flatten.compact.sum
  end
end
