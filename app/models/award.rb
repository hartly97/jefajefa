 # at top of award.rb, ABOVE class Award
require_dependency "sluggable"

class Award < ApplicationRecord
 # IMPORTANT: An Award is NOT a Meclassdal in this design.
  # Do NOT add :medal_id here; use SoldierMedal for medals.
include Categorizable
include Sluggable
include Citable
  
  # TEMP safety shim in case the concern isn't loaded yet:
  # before_validation :generate_slug, if: :needs_slug?

has_many :citations, as: :citable, dependent: :destroy

  
belongs_to :soldier, inverse_of: :awards

  validates :name, presence: true
  validates :year, numericality: { allow_nil: true, only_integer: true }

   private
  # def slug_source = [name, country, year].compact.join("-")
 # <-- add this so Sluggable knows what to slug
  # def slug_source
  #   [first_name, last_name].compact.join(" ").presence || "soldier-#{id || SecureRandom.hex(2)}"
  # end
  # define it here too (same logic as concern) so callback never fails
  def generate_slug
    base = slug_source.to_s.parameterize.presence || SecureRandom.hex(4)
    candidate, i = base, 1
    while self.class.unscoped.where(slug: candidate).where.not(id: id).exists?
      i += 1
      candidate = "#{base}-#{i}"
    end
    self.slug = candidate
  end
end




