module MaterialsHelper

  def markets_array
    @markets = Market.includes(:nick, :cost).all

    markets_array = Array.new
    @markets.each do |market|
      markets_array << market.nick.to_s + ' | ' + market.cost.to_s
    end

    markets_array
  end

  def products_array
    @products = Product.includes(:namae, :cost).all

    products_array = Array.new
    @products.each do |product|
      products_array << product.namae.to_s + ' | ' + product.cost.to_s
    end

    products_array
  end

  def is_per_product(material)
    material.per_product ? ('<small> /製品</small>').html_safe : ('<small> /箱</small>').html_safe
  end

end
