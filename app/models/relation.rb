#not using 
class Relation < ApplicationRecord
  belongs_to :from, polymorphic: true
  belongs_to :to, polymorphic: true

  validates :relation_type, presence: true
  
  validates :from_type, uniqueness: { scope: [:from_id, :to_type, :to_id, :relation_type], message: "relationship already exists" }

  validate  :prevent_self_relation

  private
  def prevent_self_relation
    if from_type == to_type && from_id == to_id
      errors.add(:base, "Cannot relate a record to itself.")
    end
  end
end

