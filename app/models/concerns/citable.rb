# app/models/concerns/citable.rb
module Citable
  extend ActiveSupport::Concern

  included do
    has_many :citations, as: :citable, dependent: :destroy, inverse_of: :citable
    has_many :sources,   through: :citations
    
    accepts_nested_attributes_for :citations,
      allow_destroy: true,
      reject_if: ->(attrs) do
        locator_keys = %w[
          page pages folio column line_number record_number locator
          image_url image_frame roll enumeration_district
          quote note
        ]
        has_source_id    = attrs['source_id'].present?
        nested           = attrs['source_attributes'].is_a?(Hash) ? attrs['source_attributes'] : {}
        has_source_title = nested['title'].present?
        any_locator      = locator_keys.any? { |k| attrs[k].present? }
        !has_source_id && !has_source_title && !any_locator

    # accepts_nested_attributes_for :citations,
    #   allow_destroy: true,
    #   reject_if: ->(attrs) do
    #     attrs.values_at('pages','quote','note','source_id').all?(&:blank?) &&
    #       (attrs['source_attributes'].blank? || attrs['source_attributes']['title'].blank?)
      end
  end
end
