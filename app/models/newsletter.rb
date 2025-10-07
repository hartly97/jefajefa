class Newsletter < ApplicationRecord
    include Sluggable
    validates :slug, presence: true, uniqueness: true

    has_rich_text :content
    has_one_attached :pdf
    validate :pdf_must_be_pdf

    private
  
    def pdf_must_be_pdf
    return unless pdf.attached?
    errors.add(:pdf, "must be a PDF") unless pdf.content_type == "application/pdf"
  end
end