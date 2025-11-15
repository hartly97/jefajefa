class CensusEntry < ApplicationRecord
  self.table_name = "census_entries"

  include Citable
  include Categorizable
  include Sluggable

  # Optional, but explicit:
  def slug_source = name
end

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
  q = q.to_s.strip
  if q.blank?
    all
  else
    like = "%#{ActiveRecord::Base.sanitize_sql_like(q)}%"

    preds = [
      "firstname ILIKE :q",
      "lastname  ILIKE :q",
      "(COALESCE(firstname,'') || ' ' || COALESCE(lastname,'')) ILIKE :q",
    ]

    preds << "slug ILIKE :q"               if column_names.include?("slug")
    preds << "birthlikeplacetext ILIKE :q" if column_names.include?("birthlikeplacetext")
    preds << "place ILIKE :q"              if column_names.include?("place")
    preds << "district ILIKE :q"           if column_names.include?("district")
    preds << "subdistrict ILIKE :q"        if column_names.include?("subdistrict")

    where(preds.join(" OR "), q: like)
  end
}

end
