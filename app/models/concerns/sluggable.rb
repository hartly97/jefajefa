# app/models/concerns/sluggable.rb
require "securerandom"

module Sluggable
  extend ActiveSupport::Concern

  included do
    # Use a plain predicate method instead of a lambda for compatibility
  before_validation :generate_slug, if: :needs_slug?
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
  end
 


  # Avoid endless methods for older Ruby versions
  # def to_param
  #   slug
  # end
  
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
    #include_private = true so it works even if slug_source is private
  slug.blank? && respond_to?(:slug_source, true)
end
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
def needs_slug?
  # include_private = true so it works even if slug_source is private
  slug.blank? && respond_to?(:slug_source, true)
end

def generate_slug
  # call the method even if it's private
  base = (respond_to?(:slug_source, true) ? send(:slug_source) : nil).to_s.parameterize
  base = base.presence || SecureRandom.hex(4)
  candidate = base
  i = 1
  while self.class.unscoped.where(slug: candidate).where.not(id: id).exists?
    i += 1
    candidate = "#{base}-#{i}"
  end
  self.slug = candidate
end



