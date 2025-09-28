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

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :topics,     -> { where(category_type: "topic") }
  scope :sources,    -> { where(category_type: "source") }
  scope :locations,  -> { where(category_type: "location") }
  scope :wars,       -> { where(category_type: "war") }
  scope :battles,    -> { where(category_type: "battle") }
  scope :medals,     -> { where(category_type: "medal") }
  scope :by_name_ci, ->(name) { where("lower(name) = ?", name.to_s.downcase) }

  def slug_source = name

  # ---- medal category helpers ----
  def self.medals_parent_name = "Medals"

  def self.ensure_medals_parent!
    by_name_ci(medals_parent_name).first_or_create!
  end

  def self.medal_children(fallback: true)
    if column_names.include?("parent_id")
      if (parent = by_name_ci(medals_parent_name).first)
        where(parent_id: parent.id).order(:name)
      else
        fallback ? where("name ILIKE ?", "%medal%").order(:name) : none
      end
    elsif reflect_on_association(:children)
      if (parent = by_name_ci(medals_parent_name).first)
        parent.children.order(:name)
      else
        fallback ? where("name ILIKE ?", "%medal%").order(:name) : none
      end
    else
      fallback ? where("name ILIKE ?", "%medal%").order(:name) : none
    end
  end
end
