# app/models/soldier.rb
class Soldier < ApplicationRecord
  include Sluggable
  include Citable
  include Categorizable
after_commit :sync_burial_involvement, if: :saved_change_to_cemetery_id?

  belongs_to :cemetery, optional: true

  has_many :burials, as: :participant, dependent: :nullify

  # Directs
  has_many :awards, inverse_of: :soldier, dependent: :destroy

  # Medals via join
  has_many :soldier_medals, inverse_of: :soldier, dependent: :destroy
  has_many :medals, through: :soldier_medals

  # Categories
  has_many :categorizations, as: :categorizable, dependent: :destroy
  has_many :categories, through: :categorizations

  # Involvements (polymorphic)
  has_many :involvements,
           as: :participant,
           inverse_of: :participant,
           dependent: :destroy
  
           has_many :battles, through: :involvements, source: :involvable, source_type: "Battle"
  
           has_many :wars,    through: :involvements, source: :involvable, source_type: "War"

  # Citations are provided by Citable; don’t redefine here.

  # Nested attributes used by your form
  accepts_nested_attributes_for :awards, :soldier_medals,  :citations,
                                allow_destroy: true, reject_if: :all_blank

  # ---- Scopes ----
  scope :by_last_first, -> { order(:last_name, :first_name) }

  scope :search_name, ->(q) {
    q = q.to_s.strip
    if q.blank?
      all
    else
      like = "%#{ActiveRecord::Base.sanitize_sql_like(q)}%"
      where(
        "first_name ILIKE :q OR last_name ILIKE :q OR " \
        "(COALESCE(first_name,'') || ' ' || COALESCE(last_name,'')) ILIKE :q OR " \
        "COALESCE(unit,'') ILIKE :q OR COALESCE(branch_of_service,'') ILIKE :q OR " \
        "COALESCE(slug,'') ILIKE :q",
        q: like
      )
    end
  }

  # ---- Presentation helpers ----
  def display_name
    return name if respond_to?(:name) && name.present?
    [first_name, last_name].compact.join(" ").presence || "Soldier ##{id}"
  end

def slug_source
    full = [first_name, middle_name, last_name].compact.join(" ").squeeze(" ").strip
    full.presence || "soldier-#{id || SecureRandom.hex(2)}"
  end

  def slug_source_changed?
    will_save_change_to_first_name? ||
    will_save_change_to_middle_name? ||
    will_save_change_to_last_name?
  end

  def birth_month_name
    birth_month.present? ? Date::ABBR_MONTHNAMES[birth_month] : nil
  end

  def death_month_name
    death_month.present? ? Date::ABBR_MONTHNAMES[death_month] : nil
  end

  def soldiername
    [first_name, middle_name, last_name].compact.reject(&:blank?).join(" ")
  end

  def mothername
    [mother_first_name, mother_last_name].compact.reject(&:blank?).join(" ")
  end

  def fathername
    [father_first_name, father_last_name].compact.reject(&:blank?).join(" ")
  end

  # Combine parts for display; you also have a real :deathplace column, which is fine to keep using.
  def birthplace
    [birthcity, birthstate, birthcountry].reject(&:blank?).join(", ")
  end

  def deathplace
    [deathcity, deathstate, deathcountry].reject(&:blank?).join(", ")
  end

  private

  def first_or_last_name_present
    if first_name.blank? && last_name.blank?
      errors.add(:base, "Must provide a first or last name.")
    end
  end

  def sync_burial_involvement
  old_cem, new_cem = saved_change_to_cemetery_id
  if old_cem.present? && old_cem != new_cem
    Involvement.where(
      involvable_type: "Cemetery", involvable_id: old_cem,
      participant_type: "Soldier",  participant_id: id,
      role: "burial"
    ).delete_all
  end

  if new_cem.present?
    Involvement.where(
      involvable_type: "Cemetery", involvable_id: new_cem,
      participant_type: "Soldier",  participant_id: id,
      role: "burial"
    ).first_or_create!
  else
    Involvement.where(
      involvable_type: "Cemetery",
      participant_type: "Soldier", participant_id: id,
      role: "burial"
    ).delete_all
  end
end
end
