
class War < ApplicationRecord
  include Sluggable
  include Citable  
  include Categorizable     # has_many :citations … accepts_nested_attributes_for :citations (from the concern)
  
has_many :involvements, as: :involvable, dependent: :destroy, inverse_of: :involvable

  validates :name, presence: true

  has_many :involvements,
           as: :involvable,
           dependent: :destroy,
           inverse_of: :involvable

  has_many :soldiers,
           through: :involvements,
           source: :participant,
           source_type: "Soldier"

  # accepts_nested_attributes_for :involvements, allow_destroy: true, reject_if: :all_blank

 
  def slug_source
    [first_name, last_name].compact.join(" ").presence || "soldier-#{id || SecureRandom.hex(2)}"
  end
end
