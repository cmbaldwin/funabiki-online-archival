class EcProduct < ApplicationRecord
  after_commit :expire_cache
  belongs_to :ec_product_type
  scope :with_reference_id, ->(reference_id) { where('cross_reference_ids @> ?', "{#{reference_id}}") }

  private

  def expire_cache
    Rails.cache.delete('ec_products_cache')
  end
end
