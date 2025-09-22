# app/models/soldier.rb
class Soldier < ApplicationRecord
  include Sluggable
  include Citable
  include Categorizable
  # include Relatable

belongs_to :cemetery, optional: true

has_many :awards, dependent: :destroy, inverse_of: :soldier
has_many :soldier_medals, dependent: :destroy
has_many :medals, through: :soldier_medals



  # ❌ Remove this if Award no longer belongs_to :medal
  # has_many :medals, through: :awards, source: :medal
  # Soldier helpers (filtered category associations
 has_many :battle_categories,
           -> { where(category_type: "battle") },
           through: :categorizations, source: :category

  has_many :war_categories,
           -> { where(category_type: "war") },
           through: :categorizations, source: :category
  # If you’re keeping Involvements for Soldier↔Battle/War:
  has_many :involvements, as: :participant, dependent: :destroy, inverse_of: :participant
  has_many :battles, through: :involvements, source: :involvable, source_type: "Battle"
  has_many :wars,    through: :involvements, source: :involvable, source_type: "War"

   accepts_nested_attributes_for :awards,         allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :citations,    allow_destroy: true, reject_if: :all_blank
#  accepts_nested_attributes_for :source,
#     reject_if: ->(attrs) { attrs['title'].blank? }
accepts_nested_attributes_for :involvements, allow_destroy: true, reject_if: :all_blank
accepts_nested_attributes_for :soldier_medals,
  allow_destroy: true,
  reject_if: :all_blank
  
  validate :first_or_last_name_present

  def slug_source
    [first_name, last_name].compact.join(" ").presence || "soldier-#{id || SecureRandom.hex(2)}"
  end

  scope :by_last_first, -> { order(:last_name, :first_name) }
  scope :search_name, ->(q) {
    next all if q.blank?
    where("LOWER(first_name) LIKE :q OR LOWER(last_name) LIKE :q", q: "%#{q.downcase}%")
  }

  private
  def first_or_last_name_present
    if first_name.blank? && last_name.blank?
      errors.add(:base, "Must provide a first or last name.")
    end
  end
end

