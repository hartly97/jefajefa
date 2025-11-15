require "securerandom"

module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_slug, if: :needs_slug?
    validates :slug, presence: true, uniqueness: { case_sensitive: false }
  end

  # Force a fresh slug from slug_source and persist it
  def regenerate_slug!
    base = (respond_to?(:slug_source, true) ? send(:slug_source) : nil).to_s.parameterize
    base = base.presence || SecureRandom.hex(4)

    candidate = base
    i = 1
    while self.class.unscoped.where(slug: candidate).where.not(id: id).exists?
      i += 1
      candidate = "#{base}-#{i}"
    end

    # Skip validations if you want to regenerate even when other fields are invalid:
    update(slug: candidate) # or: update_columns(slug: candidate)
  end

  private

  # === New: this is what your callback calls ===
  def generate_slug
    self.slug = build_unique_slug
  end

  def needs_slug?
    slug.blank? && respond_to?(:slug_source, true)
  end

  def build_unique_slug
    base = (respond_to?(:slug_source, true) ? send(:slug_source) : nil).to_s.parameterize
    base = base.presence || SecureRandom.hex(4)

    candidate = base
    i = 1
    while self.class.unscoped.where(slug: candidate).where.not(id: id).exists?
      i += 1
      candidate = "#{base}-#{i}"
    end
    candidate
  end
  # Try in this order: explicit slug_source, display_name, name, title, label
  def candidate_slug_base
    if respond_to?(:slug_source, true)
      send(:slug_source).to_s
    elsif respond_to?(:display_name)
      display_name.to_s
    elsif respond_to?(:name)
      name.to_s
    elsif respond_to?(:title)
      title.to_s
    elsif respond_to?(:label)
      label.to_s
    else
      "" # will fall back to SecureRandom
    end
  end
end

