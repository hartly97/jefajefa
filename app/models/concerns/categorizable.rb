module Categorizable
  extend ActiveSupport::Concern

  included do
    has_many :categorizations, as: :categorizable,
    dependent: :destroy, inverse_of: :categorizable
    has_many :categories, through: :categorizations

      # Generic filter, used by the convenience helpers below
  def categories_of(type)
    categories.where(category_type: type.to_s)
  end

  # Convenience helpers: available on any model that includes Categorizable
  %w[battle war medal cemetery article award ].each do |t|
    define_method("#{t}_categories") { categories_of(t) }
  end
end
end
 
