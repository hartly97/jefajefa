# app/models/category.rb
class Category < ApplicationRecord
  include Sluggable

  has_many :categorizations, dependent: :destroy
  has_many :articles,   through: :categorizations, source: :categorizable, source_type: "Article"
  has_many :soldiers,   through: :categorizations, source: :categorizable, source_type: "Soldier"
  has_many :cemeteries, through: :categorizations, source: :categorizable, source_type: "Cemetery"
  has_many :sources,    through: :categorizations, source: :categorizable, source_type: "Source"
  has_many :wars,       through: :categorizations, source: :categorizable, source_type: "War"
  has_many :battles,    through: :categorizations, source: :categorizable, source_type: "Battle"
  has_many :medals,     through: :categorizations, source: :categorizable, source_type: "Medal"
  has_many :awards,     through: :categorizations, source: :categorizable, source_type: "Award"
  has_many :censuses,   through: :categorizations, source: :categorizable, source_type: "Census"

  # Optional typed scopes (for pickers)
  scope :soldiers,  -> { where(category_type: "soldier") }
  scope :wars,      -> { where(category_type: "war") }
  scope :battles,   -> { where(category_type: "battle") }
  scope :medals,    -> { where(category_type: "medal") }
  scope :awards,    -> { where(category_type: "award") }
  scope :articles,  -> { where(category_type: "article") }
  scope :cemeteries,-> { where(category_type: "cemetery") }
  scope :censuses,  -> { where(category_type: "census") }
  scope :sources,   -> { where(category_type: "source") }

  private

  # What Sluggable should slug
  def slug_source = name
end
