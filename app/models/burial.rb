# app/models/burial.rb
class Burial < ApplicationRecord
  belongs_to :cemetery
  belongs_to :participant, polymorphic: true, optional: true

  # Treat any Soldier-linked burial as a "soldier burial"
  scope :soldiers,      -> { where(participant_type: "Soldier").where.not(participant_id: nil) }
  scope :non_soldiers,  -> { where(participant_id: nil).or(where.not(participant_type: "Soldier")) }

  # Name helpers for display/search fallbacks
  # def display_name
  #   if participant_type == "Soldier" && participant
  #     participant.respond_to?(:display_name) ? participant.display_name :
  #       [participant.first_name, participant.last_name].compact.join(" ")
  #   else
  #     [first_name, last_name].compact.join(" ").presence || "Unknown"
  #   end
  # end

  def display_name
    if soldier
      soldier.respond_to?(:display_name) ? soldier.display_name :
        [soldier.first_name, soldier.last_name].compact.join(" ").presence || "Soldier ##{soldier.id}"
    else
      [first_name, middle_name, last_name].compact.join(" ").presence || "Unnamed"

  # Simple search across linked soldier name OR local name fields
  scope :search, ->(q) do
    next all if q.to_s.strip.blank?
    term = "%#{q.strip}%"
    joins("LEFT JOIN soldiers ON burials.participant_type = 'Soldier' AND burials.participant_id = soldiers.id")
      .where(<<~SQL, term: term)
        (soldiers.first_name ILIKE :term OR soldiers.last_name ILIKE :term
         OR (COALESCE(soldiers.first_name,'') || ' ' || COALESCE(soldiers.last_name,'')) ILIKE :term)
        OR (burials.first_name ILIKE :term OR burials.last_name ILIKE :term
         OR (COALESCE(burials.first_name,'') || ' ' || COALESCE(burials.last_name,'')) ILIKE :term)
      SQL
  end

  validates :cemetery, presence: true
  validates :participant_type, inclusion: { in: ["Soldier"], allow_nil: true }, if: -> { participant_id.present? }
end
