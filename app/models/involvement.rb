class Involvement < ApplicationRecord
  # keep Article for now since you have data; easy to tighten later
#   Dont trust params for types: we force participant_type: "Soldier" and check involvable_type against a whitelist.

# Race-safe: if two requests try to create the same link, the unique index may raise RecordNotUnique. We catch it and update the context fields.

# Year sanity: prevents 0 or 99999.

# Mirrors DB rules: app-level validation matches your check constraints so errors show nicely in the UI
  ALLOWED_PARTICIPANT_TYPES = %w[Soldier].freeze
  ALLOWED_INVOLVABLE_TYPES  = %w[Battle War Cemetery].freeze
  # app/models/involvement.rb

  belongs_to :participant, polymorphic: true, inverse_of: :involvements
  belongs_to :involvable, polymorphic: true, inverse_of: :involvements

  validates :participant_type, :participant_id, :involvable_type, :involvable_id, presence: true
  validates :role, length: { maximum: 100 }, allow_blank: true
  validates :year, numericality: { only_integer: true, allow_nil: true, greater_than: 0, less_than: 3000 }

  # One link per pair (matches your unique DB index)
  validates :participant_id, uniqueness: {
    scope: [:participant_type, :involvable_type, :involvable_id],
    message: "already linked"
  }

  # Light type whitelists to match your current DB checks
  validate :participant_type_allowed
  validate :involvable_type_allowed

  # Scopes
  scope :for_participant, ->(rec) { where(participant: rec) }
  scope :for_involvable,  ->(rec) { where(involvable:  rec) }
  scope :with_role,       ->(r)   { r.present? ? where(role: r) : all }

def participant_label
  p = participant
  return "(unknown)" unless p

  # 1) Prefer the model’s own presentation method
  return p.display_name if p.respond_to?(:display_name)
  return p.soldier_name if p.respond_to?(:soldier_name)

  # 2) Common first/last pattern
  if p.respond_to?(:first_name) || p.respond_to?(:last_name)
    name = [p.try(:first_name), p.try(:last_name)].compact.join(" ").presence
    return name if name
  end

  # 3) Other typical attributes
  p.try(:name).presence ||
    p.try(:title).presence ||
    p.try(:slug).presence ||
    # 4) Final fallback
    "#{participant_type} ##{participant_id}"
end

def participant_path
  p = participant
  return nil unless p
  Rails.application.routes.url_helpers.polymorphic_path(p) rescue nil
end




  private

  def participant_type_allowed
    errors.add(:participant_type, "must be #{ALLOWED_PARTICIPANT_TYPES.join(', ')}") unless ALLOWED_PARTICIPANT_TYPES.include?(participant_type)
  end

  def involvable_type_allowed
    errors.add(:involvable_type, "must be one of: #{ALLOWED_INVOLVABLE_TYPES.join(', ')}") unless ALLOWED_INVOLVABLE_TYPES.include?(involvable_type)
  end
end
