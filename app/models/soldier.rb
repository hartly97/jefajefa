
class Soldier < ApplicationRecord
  include Sluggable
  include Citable
  include Categorizable

  belongs_to :cemetery, optional: true

  has_many :awards, dependent: :destroy

  has_many :soldier_medals, dependent: :destroy
  has_many :medals, through: :soldier_medals

  has_many :categorizations, as: :categorizable, dependent: :destroy
  has_many :categories, through: :categorizations

  has_many :involvements, as: :participant, dependent: :destroy
  has_many :battles, through: :involvements, source: :involvable, source_type: "Battle"
  has_many :wars,    through: :involvements, source: :involvable, source_type: "War"

  has_many :citations, as: :citable, dependent: :destroy

  scope :by_last_first, -> { order(:last_name, :first_name) }
  scope :search_name, ->(q) {
    like = "%#{q.to_s.downcase}%"
    next all if q.blank?
    where(
      "LOWER(first_name) LIKE :q OR LOWER(last_name) LIKE :q OR LOWER(COALESCE(first_name,'') || ' ' || COALESCE(last_name,'')) LIKE :q OR LOWER(COALESCE(name,'')) LIKE :q OR LOWER(slug) LIKE :q",
      q: like
    )
  }

  def display_name
  return name if respond_to?(:name) && name.present?
  [first_name, last_name].compact.join(" ").presence || "Soldier ##{id}"
   end

  def slug_source
    [first_name, last_name].compact.join(" ").presence || "soldier-#{id || SecureRandom.hex(2)}"
  end

  validate :first_or_last_name_present

  private
  def first_or_last_name_present
    if first_name.blank? && last_name.blank?
      errors.add(:base, "Must provide a first or last name.")
    end
  end
   def birth_month_name
   birth_month.present? ? Date::ABBR_MONTHNAMES[birth_month] : nil
  end

  def death_month_name
   death_month.present? ? Date::ABBR_MONTHNAMES[death_month] : nil
  end

  def soldiername
    [first_name || '', middle_name || '', last_name || ''].reject(&:empty?).join(' ')
  end

  def mothername
    [mother_first_name || '', mother_last_name || ''].reject(&:empty?).join(' ')
  end

  def fathername
    [father_first_name || '', father_last_name || ''].reject(&:empty?).join(' ')
  end
end