# class Involvement < ApplicationRecord
#   belongs_to :participant, polymorphic: true
#   belongs_to :involvable, polymorphic: true

#   validates :participant_type, :participant_id, :involvable_type, :involvable_id, presence: true
  
#   validates :participant_type, uniqueness: { scope: [:participant_id, :involvable_type, :involvable_id], message: "already linked" }

# validates :participant_type, :participant_id, :involvable_type, :involvable_id, presence: true

#   validates :role, length: { maximum: 100 }, allow_blank: true
#   end

#   # Handy scopes
#   scope :for_participant, ->(rec) { where(participant: rec) }
#   scope :for_involvable,  ->(rec) { where(involvable:  rec) }
#   scope :with_role,       ->(r)   { where(role: r) if r.present? }
# end


# app/models/involvement.rb
class Involvement < ApplicationRecord
  belongs_to :participant, polymorphic: true, inverse_of: :involvements
  belongs_to :involvable, polymorphic: true, inverse_of: :involvements

  validates :participant_type, :participant_id, :involvable_type, :involvable_id, presence: true
  validates :role, length: { maximum: 100 }, allow_blank: true

  # Enforce one link per (participant ↔ involvable) pair
  validates :participant_id, uniqueness: {
    scope: [:participant_type, :involvable_type, :involvable_id],
    message: "already linked"
  }

  # Handy scopes
  scope :for_participant, ->(rec) { where(participant: rec) }
  scope :for_involvable,  ->(rec) { where(involvable:  rec) }
  scope :with_role,       ->(r)   { where(role: r) if r.present? }
end
