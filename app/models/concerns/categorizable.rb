module Categorizable
  extend ActiveSupport::Concern

  included do
    has_many :categorizations, as: :categorizable, dependent: :destroy, inverse_of: :categorizable
    has_many :categories, through: :categorizations
  end

  # Filter by single type
  def categories_of(type)
    categories.where(category_type: type.to_s)
  end

  # Filter by multiple types (needed by soldier_badge_categories)
  def categories_of_types(*types)
    categories.where(category_type: types.flatten.map(&:to_s))
  end

  # Convenience helpers
  %w[battle war medal cemetery article award].each do |t|
    define_method("#{t}_categories") { categories_of(t) }
  end
end
