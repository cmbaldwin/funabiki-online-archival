module ProductsHelper

  def types_hash
    @types = ["トレイ", "チューブ", "水切り", "殻付き", "冷凍", "単品"]
    @types_hash = {"1"=>"トレイ", "2"=>"チューブ", "3"=>"水切り", "4"=>"殻付き", "5"=>"冷凍", "6"=>"単品"}
  end

  def products_by_type
    @products = Product.order(:namae).all
    types_hash
    products_by_type_hash = Hash.new
    types_hash.each do |type_id, name|
      products_by_type_hash[type_id.to_s] = Array.new
      products_by_type_hash[type_id.to_s] << name
    end
    @products.active.each do |product|
      products_by_type_hash[(@types.index(product.product_type) + 1).to_s] << product.id.to_s
    end
    products_by_type_hash
  end

  def product_collection(type_num)
    products_by_type[type_num].drop(1).map do |product_id|
      product = Product.find(product_id)
      [product.namae, product.id]
    end
  end

  def product_types_for_copy_select
    types_hash
    @types_hash.map { |i, t| [t, i] }
  end

  def product_types_for_select
    @products = Product.order(:namae).all
    product_types_set = Set.new
    @products.each do |product|
      product_types_set << product.product_type
    end
    product_types_for_select = Array.new
    product_types_set.to_a.each do |type|
      product_types_for_select << [type, type]
    end
    product_types_for_select
  end

  def get_product(product_id)
    Product.find(product_id)
  end

  def get_markets
    Market.all.order(:mjsnumber)
  end

  def get_materials
    Material.all
  end

  def get_material_by_id(material_id)
    Material.find(material_id)
  end

  def materials_by_type
    @materials = Material.all

    material_types = Set.new

    @materials.each do |material|
      material_types << material.zairyou
    end

    materials_by_type = Hash.new
    i = 0
    material_types.each do |material_name|
      i +=1
      unless materials_by_type[i].is_a?(Hash)
        materials_by_type[i] = Hash.new
      end
      materials_by_type[i][:type_name] = material_name
      unless materials_by_type[i][:material_ids].is_a?(Array)
        materials_by_type[i][:material_ids] = Array.new
      end
      @materials.each do |material|
        if material_name == material.zairyou
          materials_by_type[i][:material_ids] << material.id
        end
      end
    end
    materials_by_type
  end

  def cost_estimate_hash
    cost_estimate_hash = Hash.new
    cost_array = Array.new
    @product.materials.each do |material|
      if material.zairyou == "テープ"
        cost = (material.cost / material.divisor)
        cost_array << material.namae
        cost_array << cost.to_f
      elsif material.zairyou == "袋"
        cost = (material.cost / material.divisor) * @product.multiplier * @product.count
        cost_array << cost.to_f
        cost_array << material.namae
      elsif material.zairyou == "フタ"
        cost = material.cost * @product.multiplier
        cost_array << material.namae
        cost_array << cost.to_f
      elsif material.zairyou == "フィルム"
        cost = material.cost * @product.multiplier * @product.count
        cost_array << material.namae
        cost_array << cost.to_f
      elsif material.zairyou == "箱"
        cost = material.cost
        cost_array << material.namae
        cost_array << cost.to_f
      elsif material.zairyou == "粒氷"
        cost = material.cost
        cost_array << material.namae
        cost_array << cost.to_f
      elsif material.zairyou == "バンド"
        cost = material.cost
        cost_array << material.namae
        cost_array << cost.to_f
      elsif material.zairyou == "トレイ"
        cost = material.cost * @product.multiplier * @product.count
        cost_array << material.namae
        cost_array << cost.to_f
      elsif material.zairyou == "ラベル"
        cost = material.cost * @product.multiplier * @product.count
        cost_array << material.namae
        cost_array << cost.to_f
      end
    end
    cost_estimate_hash
  end

end
