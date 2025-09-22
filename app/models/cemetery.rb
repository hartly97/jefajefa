
 class Cemetery < ApplicationRecord
  include Sluggable
  include Categorizable
  # include Relatable
  include Citable

  has_many :soldiers

  validates :name, presence: true

  def slug_source = name
end
