class Citation < ApplicationRecord
  belongs_to :source, inverse_of: :citations
  belongs_to :citable, polymorphic: true
  validates :source, presence: true
  belongs_to :source, counter_cache: true
 validates :source_id, uniqueness: {
    scope: [:citable_type, :citable_id],
    message: "already cited for this record"
  }
  # app/models/citation.rb
accepts_nested_attributes_for :source,
  reject_if: ->(attrs) { attrs['title'].blank? && attrs['id'].blank? }

    
end
 




