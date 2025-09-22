class SoldierMedal < ApplicationRecord
  belongs_to :soldier, inverse_of: :soldier_medals
  belongs_to :medal,   inverse_of: :soldier_medals

  validates :medal_id, uniqueness: { scope: [:soldier_id, :year] }
  validates :year, numericality: { allow_nil: true, only_integer: true }
end