# app/helpers/burials_helper.rb
module BurialsHelper
  # A single row “view-model” so the table works for Soldier or Burial records
  def burial_row(record)
    OpenStruct.new(
      id:         record.id,
      klass:      record.class.name,
      name:       burial_display_name(record),
      birth:      burial_birth_text(record),
      death:      burial_death_text(record),
      path:       burial_show_path(record)
    )
  end

  # --- field normalizers ---

  def burial_display_name(record)
    return record.display_name if record.respond_to?(:display_name)

    fn = record.try(:first_name)
    ln = record.try(:last_name)
    [fn, ln].compact.join(" ").presence || "##{record.id}"
  end

  def burial_birth_text(record)
    # Soldier: birth_date + birthplace (synthesized)    | Burial: birth_date + birth_place
    date  = (record.try(:birth_date) || record.try(:birth_year))
    place = record.try(:birthplace) || record.try(:birth_place) ||
            [record.try(:birthcity), record.try(:birthstate), record.try(:birthcountry)].reject(&:blank?).join(", ").presence

    join_label_value("Birth", join_date_place(date, place))
  end

  def burial_death_text(record)
    date  = (record.try(:death_date) || record.try(:death_year))
    place = record.try(:deathplace) || record.try(:death_place) ||
            [record.try(:deathcity), record.try(:deathstate), record.try(:deathcountry)].reject(&:blank?).join(", ").presence

    join_label_value("Death", join_date_place(date, place))
  end

  # Prefer Soldier path; only link Burial if you actually have routes/views for it
  def burial_show_path(record)
    if record.is_a?(Soldier)
      record # polymorphic: link_to row.name, row.path
    elsif defined?(burial_path)
      burial_path(record)
    else
      nil
    end
  end

  # --- tiny formatters ---

  def join_date_place(date, place)
    bits = []
    bits << l(date)              if date.respond_to?(:to_date) rescue bits << date
    bits << place                if place.present?
    bits.compact.join(" — ").presence
  end

  def join_label_value(label, value)
    value.present? ? content_tag(:p, content_tag(:strong, "#{label}: ") + value) : "".html_safe
  end
end
