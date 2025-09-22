class Category < ApplicationRecord
  include Sluggable

  has_many :categorizations, dependent: :destroy
  has_many :articles, through: :categorizations, source: :categorizable, source_type: "Article"
  has_many :soldiers, through: :categorizations, source: :categorizable, source_type: "Soldier"
  has_many :cemeteries, through: :categorizations, source: :categorizable, source_type: "Cemetery"
  has_many :sources, through: :categorizations, source: :categorizable, source_type: "Source"
  has_many :wars, through: :categorizations, source: :categorizable, source_type: "War"
  has_many :battles, through: :categorizations, source: :categorizable, source_type: "Battle"
  has_many :medals, through: :categorizations, source: :categorizable, source_type: "Medal"

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :topics,    -> { where(category_type: "topic") }
  scope :sources,   -> { where(category_type: "source") }
  scope :locations, -> { where(category_type: "location") }
  scope :wars,      -> { where(category_type: "war") }
  scope :battles,   -> { where(category_type: "battle") }
  scope :medals,    -> { where(category_type: "medal") }
  def slug_source = name
end
