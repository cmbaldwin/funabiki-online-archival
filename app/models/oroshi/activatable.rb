module Oroshi
  module Activatable
    extend ActiveSupport::Concern

    included do
      validates :active, inclusion: { in: [true, false] }
      scope :active, -> { where(active: true) }
      scope :inactive, -> { where(active: false) }
    end
  end
end
