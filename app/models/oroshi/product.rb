module Oroshi
  class Product < ApplicationRecord
    # Callbacks
    include Oroshi::Activatable

    # Associations
    belongs_to :supply_type, class_name: 'Oroshi::SupplyType'
    has_and_belongs_to_many :materials,
                            class_name: 'Oroshi::Material',
                            join_table: 'oroshi_product_materials'
    has_many :product_variations, class_name: 'Oroshi::ProductVariation'
    has_many :orders, through: :product_variations
    has_many :packagings, class_name: 'Oroshi::Packaging'

    # Validations
    validates :name, presence: true
    validates :units, presence: true
    validates_numericality_of :exterior_height, :exterior_width, :exterior_depth, greater_than_or_equal_to: 0

    # Scopes
    # all records ordered by number of associated product_variations
    default_scope { order(:position) }
    scope :by_product_variation_count, lambda {
                                         left_joins(:product_variations)
                                           .group(:id)
                                           .order(Arel.sql('COUNT(oroshi_product_variations.id) DESC'), :name)
                                       }
    scope :with_product_variations, lambda {
                                      left_joins(:product_variations)
                                        .group(:id)
                                        .having('COUNT(oroshi_product_variations.id) > 0')
                                    }

    def to_s
      "#{name} (#{units})"
    end

    def material_cost(shipping_receptacle, item_quantity: 1, receptacle_quantity: @receptacle_quantity,
                      freight_quantity: nil, init_value: 0, shown_work: nil)
      @quantity = item_quantity
      @shown_work = shown_work
      @receptacle_quantity = receptacle_quantity
      @per_box = @quantity / @receptacle_quantity if receptacle_quantity&.positive?
      @per_box ||= shipping_receptacle.estimate_per_box_quantity(self)
      @per_box = 1 if @per_box&.zero?
      @per_freight = shipping_receptacle.default_freight_bundle_quantity
      @freight_quantity = freight_quantity
      materials.inject(init_value) do |sum, material|
        # Material enum per: { item: 0, shipping_receptacle: 1, freight: 2, supply_type_unit: 3 }
        init_show_material_work(material)
        add_material_cost(material, sum)
      end
    end

    def supply_volume_units
      supply_type.units
    end

    private

    def init_show_material_work(material)
      return unless @shown_work

      @shown_work['materials'][material.name] = { quantity: @quantity,
                                                  per: material.per,
                                                  cost: material.cost }
    end

    def add_material_cost(material, sum)
      case material.per
      when 'item'
        calculate_item_cost(material, sum)
      when 'shipping_receptacle'
        calculate_shipping_receptacle_cost(material, sum)
      when 'freight'
        calculate_freight_cost(material, sum)
      when 'supply_type_unit'
        calculate_supply_type_unit_cost(material, sum, primary_content_volume)
      end
    end

    def calculate_item_cost(material, sum)
      change = material.cost * @quantity
      update_shown_work(material,
                        "商品ごとのコスト: #{change}",
                        "#{material.cost} * #{@quantity}")
      sum + change
    end

    def calculate_shipping_receptacle_cost(material, sum)
      change = material.cost * (@quantity.to_f / @per_box).ceil
      update_shown_work(material,
                        "発送容器ごとのコスト: #{change}",
                        "#{material.cost} * #{@quantity} / #{@per_box}")
      sum + change
    end

    def calculate_freight_cost(material, sum)
      freight_units = @freight_quantity || [@quantity / @per_box / @per_freight, 1].max
      change = material.cost * freight_units
      update_shown_work(material,
                        "発送括りのコスト: #{change}",
                        "#{material.cost} / ((#{@quantity} / #{@per_box} / #{@per_freight} || 1)")
      sum + change
    end

    def calculate_supply_type_unit_cost(material, sum, primary_content_volume)
      change = material.cost / primary_content_volume * @quantity
      update_shown_work(material,
                        "商品供給種類単位のコスト: #{change}",
                        "#{material.cost} / #{primary_content_volume} * #{@quantity}")
      sum + change
    end

    def update_shown_work(material, text, work)
      return unless @shown_work

      @shown_work['materials'][material.name][:text] = text
      @shown_work['materials'][material.name][:work] = work
    end
  end
end
