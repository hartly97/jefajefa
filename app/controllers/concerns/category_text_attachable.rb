module CategoryTextAttachable
  extend ActiveSupport::Concern

  def attach_categories_from_text_unified(record, params_scope:, field:)
    raw   = params.dig(params_scope, field).to_s
    names = raw.split(",").map { |s| s.strip }.reject(&:blank?)
    return if names.empty?

    names.each do |name|
      existing = Category.where('LOWER(name) = ?', name.downcase).first
      cat = existing || Category.create!(name: name.titleize, category_type: "topic")
      cat.update_columns(slug: cat.name.parameterize) if cat.slug.blank?
      record.categories << cat unless record.categories.exists?(id: cat.id)
    end
  end
end


