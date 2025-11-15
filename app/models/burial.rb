# app/models/burial.rb
# class Burial < ApplicationRecord
#   include Sluggable
#   include Citable
#   include Categorizable

  
#   belongs_to :cemetery
#   belongs_to :participant, polymorphic: true, optional: true# Soldier or future Person


#   # Treat any Soldier-linked burial as a "soldier burial"
#   scope :soldiers,      -> { where(participant_type: "Soldier").where.not(participant_id: nil) }
#   scope :non_soldiers,  -> { where(participant_id: nil).or(where.not(participant_type: "Soldier")) }

#     validates :cemetery, presence: true
#   validate  :name_or_participant

#   # Name helpers for display/search fallbacks
#   def display_name
#     if participant_type == "Soldier" && participant
#       participant.respond_to?(:display_name) ? participant.display_name :
#         [participant.first_name, participant.last_name].compact.join(" ")
#     else
#       [first_name, last_name].compact.join(" ").presence || "Unknown"
#     end
#   end

# app/models/burial.rb
class Burial < ApplicationRecord
  include Sluggable
  include Citable
  include Categorizable

  belongs_to :cemetery, optional: true
  belongs_to :participant, polymorphic: true, optional: true # Soldier (today) or Person (future)
  belongs_to :soldier,  optional: true  # keep optional if you don’t always have it

  scope :q_search, ->(q) {
    q = q.to_s.strip
    next all if q.blank?
    like = "%#{q.downcase}%"
    where(<<~SQL, q: like)
      LOWER(COALESCE(first_name,'')) LIKE :q OR
      LOWER(COALESCE(middle_name,'')) LIKE :q OR
      LOWER(COALESCE(last_name,''))  LIKE :q OR
      LOWER(COALESCE(section,''))    LIKE :q OR
      LOWER(COALESCE(plot,''))       LIKE :q OR
      LOWER(COALESCE(marker,''))     LIKE :q
    SQL
  }

  # Treat any Soldier-linked burial as a "soldier burial"
  scope :soldiers,     -> { where(participant_type: "Soldier").where.not(participant_id: nil) }
  scope :non_soldiers, -> { where(participant_id: nil).or(where.not(participant_type: "Soldier")) }

  validates :cemetery, presence: true
  validate  :name_or_participant

  def display_name
  base = [try(:first_name), try(:middle_name), try(:last_name)].compact.join(" ").presence
  base || try(:name).presence || "Burial ##{id}"
end

  # ----- Presentation -----
 
  

  def display_name
    if respond_to?(:soldier) && soldier.present?
      soldier.respond_to?(:display_name) ?
        soldier.display_name :
        [soldier.try(:first_name), soldier.try(:last_name)].compact.join(" ").presence
    else
      [try(:first_name), try(:middle_name), try(:last_name)].compact.join(" ").presence
    end || "Unknown"
  end
  public :display_name
end

  # Sluggable needs a source; we synthesize one from participant or local names
  def slug_source
    if participant_type == "Soldier" && participant
      participant.respond_to?(:display_name) ? participant.display_name :
        [participant.first_name, participant.last_name].compact.join(" ")
    else
      [first_name, last_name].compact.join(" ").presence || "burial-#{id || SecureRandom.hex(3)}"
    end
  end

  # ----- Search (optional convenience) -----
  scope :search, ->(q) do
    q = q.to_s.strip
    next all if q.blank?
    term = "%#{q}%"
    joins("LEFT JOIN soldiers ON burials.participant_type = 'Soldier' AND burials.participant_id = soldiers.id")
      .where(<<~SQL, term: term)
        (soldiers.first_name ILIKE :term OR soldiers.last_name ILIKE :term
         OR (COALESCE(soldiers.first_name,'') || ' ' || COALESCE(soldiers.last_name,'')) ILIKE :term)
        OR (burials.first_name ILIKE :term OR burials.last_name ILIKE :term
         OR (COALESCE(burials.first_name,'') || ' ' || COALESCE(burials.last_name,'')) ILIKE :term)
      SQL
  end

  private

  def name_or_participant
    if participant.blank? && [first_name, last_name].all?(&:blank?)
      errors.add(:base, "Provide a soldier/person or at least a first/last name")
    end
  end


