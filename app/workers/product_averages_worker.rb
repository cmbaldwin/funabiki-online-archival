class ProductAveragesWorker
  include Sidekiq::Worker

  def perform
    # Set the average price for each Product
    save_averages(product_prices)

    GC.start
  end

  # Iterate through each Profit adding it to the array
  def product_prices
    Profit.all.each_with_object({}) do |profit, memo|
      profit.figures.each do |_type_id, type_hash|
        next unless type_hash.is_a?(Hash)

        type_hash.each do |product_id, product_hash|
          accumulate_prices(product_id, product_hash, memo)
        end
      end
    end
  end

  def accumulate_prices(product_id, product_hash, memo)
    product_hash.each do |_market_id, values_hash|
      next unless values_hash[:order_count].positive?

      memo[product_id] ||= []
      memo[product_id] << values_hash[:unit_price] if values_hash[:unit_price].positive?
    end
  end

  def save_averages(averages)
    averages.each do |product_id, price_array|
      product = Product.find(product_id)
      average_price = price_array.empty? ? 0 : (price_array.sum / price_array.length)
      product.average_price = average_price
      product.save
    end
  end
end
