# # # class Article < ApplicationRecord
# # #   include Sluggable
# # #   include Citable
# # #   include Categorizable

# # #   validates :title, presence: true
# # #   def slug_source = title
# # # end

# # # app/models/article.rb
# # # class Article < ApplicationRecord
# # #   include Citable
# # #   include Categorizable

# # #   validate :at_least_one_complete_citation

# # #   private

# # #   def at_least_one_complete_citation
# # #     kept = citations.reject(&:marked_for_destruction?)

# # #     has_complete = kept.any? do |c|
# # #       # either picked an existing source…
# # #       c.source_id.present? ||
# # #       # …or created a new one inline (must have a title)
# # #       (c.source && c.source.title.present?)
# # #     end

# # #     errors.add(:base, "At least one citation with a source is required.") unless has_complete
# # #   end
# # # end

# # # app/models/article.rb
# # # class Article < ApplicationRecord
# # #   include Citable        # gives has_many :citations, :sources through :citations
# # #   include Categorizable  # if you categorize articles
# # #   # No “at least one citation” validation unless you want it.
# # # end

# # # # app/models/article.rb
# # # class Article < ApplicationRecord
# # #   include Sluggable           # ← add this
# # #   include Citable
# # #   include Categorizable

# # #   validates :title, presence: true
# # # has_many :citations, as: :citable, dependent: :destroy, inverse_of: :citable
# # # has_many :sources, through: :citations
# # #   # Sluggable uses this to build the slug
# # #   def slug_source = title
# # # end

# # # class Article < ApplicationRecord
# # #   include Sluggable
# # #   include Citable
# # #   include Categorizable

# # #   validates :title, presence: true
# # #   def slug_source = title
# # # end
# # class Article < ApplicationRecord
# #   include Sluggable
# #   include Citable
# #   include Categorizable
# #   include Relatable
# #   has_many :sources, through: :citations   # <= keep this
# #   accepts_nested_attributes_for :citations, allow_destroy: true

  
# # has_many :involvement, as: :involvable, dependent: :destroy, inverse_of: :involvable

# # validates :title, presence: true
# #   def slug_source = title
# # end


# # app/models/article.rb
# class Article < ApplicationRecord
#   include Sluggable
#   include Citable
#   include Categorizable
#   include Relatable

#   has_many :sources, through: :citations
#   has_many :involvements, as: :involvable, dependent: :destroy, inverse_of: :involvable

#   validates :title, presence: true
#   def slug_source = title
# end


# app/models/article.rb
class Article < ApplicationRecord
  include Sluggable
  include Citable
  include Categorizable


  has_many :sources, through: :citations
  has_many :involvements, as: :involvable, dependent: :destroy, inverse_of: :involvable

  validates :title, presence: true
  def slug_source = title
end

