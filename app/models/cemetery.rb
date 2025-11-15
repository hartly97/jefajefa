class Cemetery < ApplicationRecord
  include Sluggable
  include Categorizable
  include Citable

  has_many :burials, dependent: :destroy


   # Only the burial rows
  has_many :burial_involvements,
           -> { where(role: "burial") },
           class_name: "Involvement",
           as: :involvable
           
  has_many :buried_soldiers,
           through: :burials,
           source: :participant,
           source_type: "Soldier"


  has_many :citations, as: :citable, dependent: :destroy

  has_many :involvements, as: :involvable, dependent: :destroy, inverse_of: :involvable

  # has_many :soldiers, through: :involvements, source: :participant, source_type: "Soldier"

  validates :name, presence: true

 has_many :buried_soldiers, through: :burials, source: :participant, source_type: "Soldier"
end


# # app/models/cemetery.rb
# class Cemetery < ApplicationRecord
#   include Sluggable
#   include Citable
#   include Categorizable

#   has_many :soldiers, dependent: :nullify

#   # If you want soldiers listed through Involvements too, keep this:
#   has_many :involvements, as: :involvable, dependent: :destroy, inverse_of: :involvable
#   has_many :participants, through: :involvements, source: :participant, source_type: "Soldier"

#   validates :name, presence: true

#   private

#   # Sluggable uses this
#   def slug_source = name
# end
