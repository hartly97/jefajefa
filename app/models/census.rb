# app/models/census.rb
class Census < ApplicationRecord
  # Rails already infers the table name "censuses".
  # Keep this only if you've deliberately renamed the table.
  # self.table_name = "censuses"

  include Sluggable
  include Citable
  include Categorizable

  has_many :census_entries, dependent: :destroy

  validates :country, :year, presence: true
  # If your Sluggable concern doesn't add this, keep it:
  validates :slug, presence: true, uniqueness: true

  # Optional: store SmugMug (or other) external image URLs safely
  validates :external_image_url,
           format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                     allow_blank: true }

  # Used by Sluggable to derive a stable slug base
  def slug_source
    [country, year, district, subdistrict, piece, folio, page].compact.join("-")
  end

  # Prefer SmugMug/external URL; fall back to Active Storage if you ever attach
  # has_one_attached :image
  def display_image_url(view_context = nil)
    return external_image_url if external_image_url.present?
    return view_context.url_for(image) if respond_to?(:image) &&
                                          image.respond_to?(:attached?) &&
                                          image.attached? &&
                                          view_context
    nil
  end
end
