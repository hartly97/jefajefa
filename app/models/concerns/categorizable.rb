module Categorizable
  extend ActiveSupport::Concern

  included do
    has_many :categorizations, as: :categorizable,
    dependent: :destroy,
                               inverse_of: :categorizable
    has_many :categories, through: :categorizations
  end
end
