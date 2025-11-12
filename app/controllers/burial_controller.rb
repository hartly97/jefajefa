# app/models/burial.rb
class Burial < ApplicationRecord
  belongs_to :cemetery
  belongs_to :participant, polymorphic: true, optional: true # Soldier or future Person

  validates :cemetery, presence: true
  validate  :name_or_participant

  def display_name
    if participant.respond_to?(:display_name)
      participant.display_name
    else
      [first_name, middle_name, last_name].compact.join(" ").presence || "Unnamed burial"
    end
  end

  private

  def name_or_participant
    if participant.blank? && [first_name, last_name].all?(&:blank?)
      errors.add(:base, "Provide a soldier/person or at least a first/last name")
    end
  end
end



# app/models/soldier.rb (add)
has_many :burials, as: :participant, dependent: :nullify
