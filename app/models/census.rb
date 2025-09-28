# app/models/census.rb
class Census < ApplicationRecord
  include Citable
  include Sluggable
  has_many :census_entries, dependent: :destroy
  validates :country, :year, :slug, presence: true
has_many :citations, as: :citable, dependent: :destroy
  # If you ever want to store images locally too:
  # has_one_attached :image

  def slug_source
    [country, year, district, subdistrict, piece, folio, page].compact.join("-").parameterize
  end

  # Prefer SmugMug but fall back to Active Storage URL if attached
  def display_image_url(view_context = nil)
    return image_url if image_url.present?
    return view_context.url_for(image) if respond_to?(:image) && image.attached? && view_context
    nil
  end
end
