 class Award < ApplicationRecord
 # IMPORTANT: An Award is NOT a Meclassdal in this design.
  # Do NOT add :medal_id here; use SoldierMedal for medals.
include Categorizable
include Sluggable
include Citable
  has_many :citations, as: :citable, dependent: :destroy

  belongs_to :soldier, inverse_of: :awards

  validates :name, presence: true
  validates :year, numericality: { allow_nil: true, only_integer: true }
 end


