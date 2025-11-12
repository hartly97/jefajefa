class Cemetery < ApplicationRecord
  include Sluggable
  include Categorizable
  include Citable

  has_many :burials, dependent: :destroy

has_many :involvements, as: :involvable, dependent: :destroy

   # Only the burial rows
  has_many :burial_involvements,
           -> { where(role: "burial") },
           class_name: "Involvement",
           as: :involvable
           
  has_many :buried_soldiers,
           through: :burials,
           source: :participant,
           source_type: "Soldier"

             has_many :involvements, as: :involvable, dependent: :destroy

  has_many :citations, as: :citable, dependent: :destroy

  # has_many :involvements, as: :involvable, dependent: :destroy, inverse_of: :involvable

  # has_many :soldiers, through: :involvements, source: :participant, source_type: "Soldier"

  validates :name, presence: true

   def slug_source
  base = [name, city, state, country].compact.map(&:to_s).reject(&:blank?).join(" ")
    base.presence || "cemetery-#{id || SecureRandom.hex(2)}"

    has_many :buried_soldiers, through: :burials, source: :participant, source_type: "Soldier"
end
end
