module Oroshi
  class Order < ApplicationRecord
    # Associations
    belongs_to :buyer, class_name: 'Oroshi::Buyer'
    belongs_to :product_variation, class_name: 'Oroshi::ProductVariation'
    has_one :product, through: :product_variation
    belongs_to :product_inventory, class_name: 'Oroshi::ProductInventory'
    belongs_to :shipping_receptacle, class_name: 'Oroshi::ShippingReceptacle'
    belongs_to :shipping_method, class_name: 'Oroshi::ShippingMethod'
    has_one :order_template, class_name: 'Oroshi::OrderTemplate', inverse_of: :order, dependent: :destroy

    # Enumerables
    enum status: { estimate: 0, confirmed: 1, shipped: 2 }

    # Validations
    validates :arrival_date, :shipping_date, :manufacture_date, :expiration_date, presence: true
    validates :item_quantity, :receptacle_quantity, :freight_quantity,
              presence: true, numericality: { greater_than: 0 }
    validates :shipping_cost, :materials_cost, :sale_price_per_item, :adjustment,
              presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :note, length: { maximum: 255 }

    # Attributes
    attr_accessor :previous_item_quantity, :data, :is_order_template, :copy_template
    attr_writer :manufacture_date, :expiration_date

    def manufacture_date
      product_inventory&.manufacture_date || @manufacture_date
    end

    def expiration_date
      product_inventory&.expiration_date || @expiration_date
    end

    def counts
      [item_quantity, receptacle_quantity, freight_quantity]
    end

    # Callbacks
    before_validation :set_or_create_product_inventory, on: %i[create update]
    after_validation :calculate_costs
    before_update :store_previous_product_inventory
    before_update :store_previous_item_quantity
    after_update :update_product_inventory
    after_update :check_and_destroy_previous_product_inventory
    before_destroy :restore_product_inventory
    after_destroy :check_and_destroy_product_inventory
    before_save :handle_order_template

    # Scopes
    # Orders associated as templates do not count as actual orders
    scope :non_template, -> { where.not(id: Oroshi::OrderTemplate.select(:order_id).distinct) }
    # scope :with_template, -> { unscoped.where(id: Oroshi::OrderTemplate.select(:order_id).distinct) }
    # scope :today, -> { where(shipping_date: Time.zone.today) }
    # scope :estimate, -> { where(status: statuses[:estimate]) }
    # scope :confirmed, -> { where(status: statuses[:confirmed]) }
    # scope :unshipped, -> { where.not(status: statuses[:shipped]) }
    # scope :shipped, -> { where(status: statuses[:shipped]) }
    # scope :sold, -> { where.not(sale_price_per_item: 0) }

    # Broadcasts
    broadcasts_to ->(order) { ["product_variation_#{order.product_variation.id}_orders_templates", :edit] }, on: :create
    broadcasts_to ->(order) { [order, :edit] }, on: :update
    broadcasts_to ->(order) { [order, :destroy] }, on: :destroy

    def to_s
      "#{buyer.handle} #{shipping_date} #{model_name.human}#{id} - #{product_variation} * #{item_quantity} [#{shipping_receptacle.handle}*#{receptacle_quantity}]"
    end

    def revenue
      sale_price_per_item * item_quantity
    end

    def revenue_minus_handling
      revenue * buyer.commission_percentage
    end

    def expenses
      materials_cost + shipping_cost - adjustment
    end

    def total
      revenue - expenses
    end

    private

    # Inventory management setup
    def set_or_create_product_inventory
      self.product_inventory = Oroshi::ProductInventory.find_or_create_by(
        product_variation:,
        manufacture_date:,
        expiration_date:
      )
    end

    def store_previous_product_inventory
      @previous_product_inventory = product_inventory
    end

    def check_and_destroy_previous_product_inventory
      return unless @previous_product_inventory.orders.unscoped.empty?

      @previous_product_inventory.destroy
    end

    def check_and_destroy_product_inventory
      return unless product_inventory.orders.unscoped.empty?

      product_inventory.destroy
    end

    # Cost calculation
    def calculate_costs
      self.shipping_cost = calculate_shipping_cost
      self.materials_cost = calculate_materials_cost
    end

    def calculate_shipping_cost
      # If the order is bundled with another order, the shipping costs are 0 for this one
      return 0 if bundled_with_order_id.present?

      # Shipping method costs
      per_receptacle_shipping_method_cost = shipping_method&.per_shipping_receptacle_cost || 0
      per_freight_shipping_method_cost = shipping_method&.per_freight_unit_cost || 0
      # Buyer costs
      buyer_handling_cost = buyer&.handling_cost || 0
      buyer_optional_cost = add_buyer_optional_cost ? buyer.optional_cost : 0
      # Shipping subtotals
      receptacle_shipping_cost = receptacle_quantity * (buyer_handling_cost + buyer_optional_cost + per_receptacle_shipping_method_cost)
      freight_cost = freight_quantity * per_freight_shipping_method_cost
      # Total shipping cost
      receptacle_shipping_cost + freight_cost
    end

    def calculate_materials_cost
      receptacle_cost = bundled_shipping_receptacle ? 0 : (shipping_receptacle&.cost || 0) * receptacle_quantity
      product_cost = product&.material_cost(shipping_receptacle,
                                            item_quantity:,
                                            receptacle_quantity:,
                                            freight_quantity:) || 0
      packaging_cost = (product_variation&.packaging_cost || 0) * item_quantity
      receptacle_cost + product_cost + packaging_cost
    end

    # Inventory management
    def store_previous_item_quantity
      self.previous_item_quantity = item_quantity_was if shipped? || status_was == 'shipped'
    end

    def update_product_inventory
      return unless shipped?

      difference = previous_item_quantity - item_quantity
      product_inventory = product_variation.product_inventory

      if status_before_last_save == 'shipped' # Was already shipped, record difference
        product_inventory.quantity += difference
      else # Was moved to shipped, subtract quantity
        product_inventory.quantity -= item_quantity
      end
      self.data = attributes
      product_inventory.save!
    end

    def restore_product_inventory
      return unless shipped?

      product_inventory = product_variation.product_inventory
      product_inventory.quantity += item_quantity
      product_inventory.save!
    end

    def handle_order_template
      if is_order_template && !order_template.present?
        Oroshi::OrderTemplate.create(order: self)
      elsif !is_order_template && order_template.present?
        order_template.destroy
      end
    end
  end
end
