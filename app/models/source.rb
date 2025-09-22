#   class Source < ApplicationRecord
#   include Sluggable
#   include Categorizable
#  include Relatable
 
#   has_many :citations, dependent: :restrict_with_error, inverse_of: :source

#   # 👇 Add this:
#   has_many :cited_articles,
#            through: :citations,
#            source:  :citable,
#            source_type: "Article"
#            has_many :cited_soldiers, through: :citations, source: :citable, source_type: "Soldier"

# # New: curated + recent scopes
#   scope :common,   -> { where(common: true).order(:title) }
#   scope :recent,   -> { order(updated_at: :desc).limit(15) }
#   scope :by_title, -> { order(:title) }

#   validates :title, presence: true
#   def slug_source = title
# end


# app/models/source.rb
class Source < ApplicationRecord
  include Sluggable
  include Categorizable
  include Relatable

  has_many :citations, dependent: :restrict_with_error, inverse_of: :source

  has_many :cited_articles, through: :citations, source: :citable, source_type: "Article"
  has_many :cited_soldiers, through: :citations, source: :citable, source_type: "Soldier"

  scope :common,   -> { where(common: true).order(:title) }
  scope :recent,   -> { order(updated_at: :desc).limit(15) }
  scope :by_title, -> { order(:title) }

  validates :title, presence: true
  def slug_source = title
end
