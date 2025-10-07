
# app/models/census_entry.rb
class CensusEntry < ApplicationRecord
  self.table_name = "census_entries"

  include Citable
  include Categorizable
  include Sluggable

  belongs_to :census
  belongs_to :soldier, optional: true

  # Uncomment if you actually attach files:
  # has_one_attached :image

  validates :external_image_url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                      allow_blank: true }

  # Prefer external (SmugMug) URL; fallback to ActiveStorage URL if attached
  def display_image_url(view_context = nil)
    return external_image_url if external_image_url.present?
    if respond_to?(:image) && image.respond_to?(:attached?) && image.attached? && view_context
      view_context.url_for(image)
    end
  end

  def display_name
    [firstname, lastname].compact.join(" ").presence || "Entry ##{id}"
  end
scope :search_name, ->(q) {
  like = "%#{q}%"

  # Always-present pieces
  predicates = [
    "firstname ILIKE :q",
    "lastname  ILIKE :q",
    "(firstname || ' ' || lastname) ILIKE :q"
  ]

  # Only add optional columns if they exist in this table
  predicates << "slug ILIKE :q"                  if column_names.include?("slug")
  predicates << "birthlikeplacetext ILIKE :q"    if column_names.include?("birthlikeplacetext")
  predicates << "place ILIKE :q"                 if column_names.include?("place")
  predicates << "district ILIKE :q"              if column_names.include?("district")
  predicates << "subdistrict ILIKE :q"           if column_names.include?("subdistrict")

  where(predicates.join(" OR "), q: like)
}

  scope :search_name, ->(q) {
    like = "%#{q}%"
    where(
      "firstname ILIKE :q OR lastname ILIKE :q OR " \
      "(firstname || ' ' || lastname) ILIKE :q OR " \
      "COALESCE(name,'') ILIKE :q OR COALESCE(slug,'') ILIKE :q",
      q: like
    )
  }
   predicates << "slug ILIKE :q"                  if column_names.include?("slug")
  predicates << "birthlikeplacetext ILIKE :q"    if column_names.include?("birthlikeplacetext")
  predicates << "place ILIKE :q"                 if column_names.include?("place")
  predicates << "district ILIKE :q"              if column_names.include?("district")
  predicates << "subdistrict ILIKE :q"           if column_names.include?("subdistrict")

  private

  def slug_source
    display_name.presence || "entry-#{id || SecureRandom.hex(2)}"
  end
end
