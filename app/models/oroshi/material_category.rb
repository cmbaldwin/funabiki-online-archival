module Oroshi
  class MaterialCategory < ApplicationRecord
    # Callbacks
    include Oroshi::Activatable

    # Associations
    has_many :materials, class_name: 'Oroshi::Material', dependent: :destroy

    # Validations
    validates :name, presence: true
  end
end
