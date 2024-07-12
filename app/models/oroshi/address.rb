module Oroshi
  class Address < ApplicationRecord
    # Associations
    belongs_to :addressable, polymorphic: true

    # Validations
    # empty addresses are allowed

    def country
      Carmen::Country.coded(country_id.to_s.rjust(3, '0'))
    end

    def subregion
      country.subregions.coded(subregion_id.to_s)
    end

    def invoice_line
      # 〒678-0232 兵庫県赤穂市中広1576―11
      "#{subregion}#{city}#{address1} #{address2}"
    end
  end
end
