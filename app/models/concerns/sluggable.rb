require "securerandom"

module Sluggable
  extend ActiveSupport::Concern

  included do
    # Use a plain predicate method instead of a lambda for compatibility
  before_validation :generate_slug, if: :needs_slug?
  
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
  end

def regenerate_slug!
  base = (respond_to?(:slug_source, true) ? send(:slug_source) : nil).to_s.parameterize
  base = base.presence || SecureRandom.hex(4)
  candidate = base
  i = 1
  while self.class.unscoped.where(slug: candidate).where.not(id: id).exists?
    i += 1
    candidate = "#{base}-#{i}"
  end
  update(slug: candidate)
end
  

private
# Decide whether to create/refresh automatically
  def refresh_slug_if_needed
    return if will_save_change_to_slug? # user manually edited slug, respect it

    if needs_slug? || should_refresh_slug?
      self.slug = build_unique_slug
    end
  end

  def needs_slug?
    slug.blank? && respond_to?(:slug_source, true)
  end

  # Refresh only if the model says the underlying source changed
  # (Model should implement `slug_source_changed?`; default is no-op/false.)
  def should_refresh_slug?
    respond_to?(:slug_source_changed?, true) && send(:slug_source_changed?)
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
end


