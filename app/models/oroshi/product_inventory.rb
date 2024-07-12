module Oroshi
  class ProductInventory < ApplicationRecord
    # Associations
    belongs_to :product_variation, class_name: 'Oroshi::ProductVariation'
    has_many :orders, class_name: 'Oroshi::Order'
    has_many :production_requests, class_name: 'Oroshi::ProductionRequest'

    # Validations
    validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates_uniqueness_of :manufacture_date, scope: %i[product_variation_id expiration_date],
                                               message: 'この在庫はもうすでに存在してます'
    validates :manufacture_date, :expiration_date, presence: true
    validate :expiration_date_after_manufacture_date
    validate :immutable_fields, on: :update

    # Scopes
    scope :by_manufacture_date, ->(query_dates) { where(manufacture_date: query_dates) }

    def to_s
      "#{manufacture_date.strftime('%m月%d日')} +#{(expiration_date - manufacture_date).to_i}日"
    end

    def to_short_s
      "+#{(expiration_date - manufacture_date).to_i}日"
    end

    def freight_quantity
      # item quantity / items_per_box / freight_bundle_quantity
      quantity /
        product_variation.find_per_box_quantity /
        product_variation.default_shipping_receptacle.default_freight_bundle_quantity
    end

    def convert_outstanding_orders_to_requests
      order_item_sum = orders.map do |order|
        next if order.shipped?

        order.item_quantity
      end.sum

      request_item_sum = production_requests.map do |production_request|
        next if production_request.completed?

        production_request.quantity
      end.sum

      request_amount = order_item_sum - request_item_sum
      return if request_amount.zero?

      production_requests.create!(product_inventory: self, request_quantity: request_amount)
    end

    private

    def expiration_date_after_manufacture_date
      return if manufacture_date.blank? || expiration_date.blank?

      return unless expiration_date <= manufacture_date

      errors.add(:expiration_date, '製造日以降であること')
    end

    def immutable_fields
      return unless manufacture_date_changed? || expiration_date_changed? || product_variation_id_changed?

      errors.add(:base, '製造日、消費期限、製品バリエーションは作成後に変更することはできません。')
    end
  end
end
