class Medal < ApplicationRecord
#   include Sluggable
  include Citable
  include Categorizable

  has_many :soldier_medals, dependent: :destroy, inverse_of: :medal
  has_many :soldiers, through: :soldier_medals

  validates :name, presence: true, uniqueness: true

  def slug_source = name
end

#   has_many :involvements, as: :involvable, dependent: :destroy
#   has_many :soldiers, through: :involvements, source: :participant, source_type: "Soldier"

#   def slug_source = name
# end

# # app/models/medal.rb
# class Medal < ApplicationRecord
#   include Sluggable
#   has_many :soldier_medals, dependent: :destroy
#   has_many :soldiers, through: :soldier_medals
#   validates :name, presence: true, uniqueness: true
#   def slug_source = name
# end

# app/models/medal.rb
class Medal < ApplicationRecord
  include Sluggable
  include Citable
  include Categorizable
  has_many :soldier_medals, dependent: :destroy
  has_many :soldiers, through: :soldier_medals
  validates :name, presence: true, uniqueness: true
  def slug_source = name
end
