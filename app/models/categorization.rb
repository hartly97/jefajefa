class Categorization < ApplicationRecord
  belongs_to :category
  belongs_to :categorizable, polymorphic: true

  validates :category_id, presence: true
  validates :categorizable_type, presence: true
  validates :categorizable_id, presence: true
  validates :category_id, uniqueness: { scope: [:categorizable_type, :categorizable_id] }
end
