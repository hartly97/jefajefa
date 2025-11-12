class Medal < ApplicationRecord
  include Sluggable
  include Citable
  include Categorizable
  has_many :soldier_medals, dependent: :destroy
  has_many :soldiers, through: :soldier_medals
    has_many :citations, as: :citable, dependent: :destroy
  validates :name, presence: true, uniqueness: true
  def slug_source
    [first_name, last_name].compact.join(" ").presence || "soldier-#{id || SecureRandom.hex(2)}"
  end

  
end
