class Article < ApplicationRecord
  include Sluggable
  include Citable
  include Categorizable


  has_many :sources, through: :citations
  has_many :involvements, as: :involvable, dependent: :destroy, inverse_of: :involvable

  validates :title, presence: true
end

