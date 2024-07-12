module Oroshi
  class ProductVariation < ApplicationRecord
    # Callbacks
    include Oroshi::Activatable

    # Attachments
    has_one_attached :image

    # Associations
    belongs_to :product, class_name: 'Oroshi::Product', foreign_key: 'product_id'
    has_one :supply_type, through: :product
    belongs_to :default_shipping_receptacle, class_name: 'Oroshi::ShippingReceptacle'
    has_and_belongs_to_many :packagings,
                            class_name: 'Oroshi::Packaging',
                            join_table: 'oroshi_product_variation_packagings'
    has_and_belongs_to_many :production_zones,
                            class_name: 'Oroshi::ProductionZone',
                            join_table: 'oroshi_product_variation_production_zones'
    has_and_belongs_to_many :supply_type_variations,
                            class_name: 'Oroshi::SupplyTypeVariation',
                            join_table: 'oroshi_product_variation_supply_type_variations'
    has_many :product_inventories, class_name: 'Oroshi::ProductInventory'
    has_many :production_requests, class_name: 'Oroshi::ProductionRequest'
    has_many :orders, class_name: 'Oroshi::Order'

    # Validations
    validates :name, presence: true
    validates :handle, presence: true
    validates :default_shipping_receptacle_id, presence: true
    validates :production_zones, presence: true
    validates :primary_content_volume, presence: true, numericality: true
    validates :primary_content_country_id, presence: true # Carmen numeric_code
    validates :primary_content_subregion_id, presence: true # Carmen coded
    validates :shelf_life, allow_blank: true, numericality: { only_integer: true } # In days

    def country
      Carmen::Country.coded(primary_content_country_id.to_s)
    end

    def region
      country.subregions.coded(primary_content_subregion_id.to_s)
    end

    def to_s
      "#{name} - #{primary_content_volume} - #{region}"
    end

    def production_supply_name
      "#{region} - #{supply_type.name}<br>(#{supply_type_variations.map(&:name).join(', ')})"
    end

    def production_cost_estimate(shipping_receptacle: default_shipping_receptacle, quantity: nil)
      @shipping_receptacle = shipping_receptacle
      per_box = find_per_box_quantity
      @quantity = quantity || per_box
      @shown_work = {}
      per_box = 1 if per_box.zero?
      @shown_work['title'] = "#{@shipping_receptacle.name} の発送容器で #{name} #{product.name} x #{@quantity} のコスト計算説明。"
      value = (@quantity.to_f / per_box).ceil * @shipping_receptacle.cost
      @shown_work['shipping_receptacle'] =
        "発送容器: (商品変種数量 #{@quantity}) / (1発送容器あたりの見積もり: #{per_box} || 1) * #{@shipping_receptacle.cost.to_f} = #{value}"
      value += packaging_cost * @quantity
      @shown_work['packagings'] =
        "商品包装（#{packagings.map(&:name).join(', ')}）: #{packaging_cost} * #{@quantity} = #{packaging_cost * @quantity}"
      @shown_work['materials'] = {}
      final_value = product.material_cost(@shipping_receptacle, item_quantity: @quantity, init_value: value,
                                                                shown_work: @shown_work)
      [final_value, @shown_work]
    end

    def find_per_box_quantity
      default = default_per_box
      return default if default&.positive?

      spacing_volume_adjustment = self.spacing_volume_adjustment || 0.90
      default_shipping_receptacle.estimate_per_box_quantity(product, adjustment: spacing_volume_adjustment || 0.90)
    end

    def packaging_cost
      packagings.sum(:cost)
    end

    private

    def create_product_inventory
      Oroshi::ProductInventory.create!(product_variation: self)
    end
  end
end
