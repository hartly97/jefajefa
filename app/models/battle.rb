class Battle < ApplicationRecord
  include Sluggable
  include Citable
  include Categorizable
 
has_many :citations, as: :citable, dependent: :destroy


  has_many :involvements, as: :involvable, dependent: :destroy
  has_many :soldiers, through: :involvements, source: :participant, source_type: "Soldier"

  validates :name, presence: true

  def slug_source = name
end
