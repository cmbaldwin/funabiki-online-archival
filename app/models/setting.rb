class Setting < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
