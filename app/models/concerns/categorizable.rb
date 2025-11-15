module Categorizable
  extend ActiveSupport::Concern

  included do
    has_many :categorizations, as: :categorizable,
             dependent: :destroy, inverse_of: :categorizable
    has_many :categories, through: :categorizations

    # Uncomment only if you actually nest categorizations on a form
    accepts_nested_attributes_for :categorizations, allow_destroy: true
  end

  # Filter by a single type (symbol or string OK)
  def categories_of(type)
    categories.where(category_type: type.to_s)
  end

 # Filter by multiple types (needed by soldier_badge_categories)
  def categories_of_types(*types)
    list = types.flatten.compact.map!(&:to_s)
    categories.where(category_type: list)
  end

  # Convenience helpers
  %w[battle war medal census cemetery article award].each do |t|
    define_method("#{t}_categories") { categories_of(t) }
  end

 
  # Virtual attr: set categories by comma-separated names
  def category_names=(csv)
    names = Array(csv.to_s.split(",")).map { |s| s.strip.presence }.compact.uniq
    self.categories = Category.where(name: names)
  end

  # Virtual attr: read categories as comma-separated names
  def category_names
    categories.order(:name).pluck(:name).join(", ")
  end

  module ClassMethods
    # Query helpers
    def with_category(category)
      joins(:categories).where(categories: { id: category.is_a?(Category) ? category.id : category })
    end

    def with_category_name(name)
      joins(:categories).where("LOWER(categories.name) = ?", name.to_s.downcase)
    end

    def with_category_type(type)
      joins(:categories).where(categories: { category_type: type.to_s })
    end

    # Convenience helpers
   %w[battle war medal census cemetery article award].each do |t|
    define_method("#{t}_categories") { categories_of(t) }

  end
end
end
