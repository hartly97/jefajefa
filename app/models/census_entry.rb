# app/models/census_entry.rb
class CensusEntry < ApplicationRecord
    self.table_name = "censuses" 
  include Citable
  include Categorizable
  include Sluggable

  # has_one_attached :image

  validates :external_image_url,
           format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                     allow_blank: true }

  # Your view already calls this; make it return the external URL.
  def display_image_url(_view_context = nil)
    external_image_url.presence
  end
  # Optional: a helper you already use in the view
  def display_image_url(_view_context = nil)
    image.attached? ? Rails.application.routes.url_helpers.url_for(image) : nil
  end
  belongs_to :census
  belongs_to :soldier, optional: true

  def display_name
    [firstname, lastname].compact.join(" ")
  end
end

private 
def slug_source = display_name.presence || "entry-#{id || SecureRandom.hex(2)}"

  scope :search_name, ->(q) {
    like = "%#{q}%"
    where(
      "first_name ILIKE :q OR last_name ILIKE :q OR "\
      "(first_name || ' ' || last_name) ILIKE :q OR "\
      "COALESCE(name,'') ILIKE :q OR slug ILIKE :q",
      q: like
    )
  }
