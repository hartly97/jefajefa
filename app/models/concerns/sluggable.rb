# app/models/concerns/sluggable.rb
require "securerandom"

module Sluggable
  extend ActiveSupport::Concern

  included do
    # Use a plain predicate method instead of a lambda for compatibility
    before_validation :generate_slug, if: :needs_slug?
    validates :slug, presence: true, uniqueness: true
  end

  # Avoid endless methods for older Ruby versions
  def to_param
    slug
  end
  def regenerate_slug!
      base = slug_source.to_s.parameterize if respond_to?(:slug_source)
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

  # Runs in the model instance
  def needs_slug?
    slug.blank? && respond_to?(:slug_source)
  end

  def generate_slug
    base = slug_source.to_s.parameterize if respond_to?(:slug_source)
    base = base.presence || SecureRandom.hex(4)

    candidate = base
    i = 1
    # Ensure uniqueness (works even if record not persisted yet)
    while self.class.unscoped.where(slug: candidate).where.not(id: id).exists?
      i += 1
      candidate = "#{base}-#{i}"
    end
    self.slug = candidate
  end
end

