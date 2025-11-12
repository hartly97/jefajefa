class CemeteriesController < ApplicationController
def show
  @q = params[:q].to_s.strip.downcase

  # 1) Real Burials (with optional search)
  burials_scope = @cemetery.burials.left_joins(:participant)
  if @q.present?
    burials_scope = burials_scope.where(
      "LOWER(COALESCE(burials.first_name,'') || ' ' || COALESCE(burials.last_name,'')) LIKE :q OR " \
      "LOWER(COALESCE(soldiers.first_name,'') || ' ' || COALESCE(soldiers.last_name,'')) LIKE :q",
      q: "%#{@q}%"
    )
  end
  real_burials = burials_scope.to_a

  # 2) Fallback: Soldiers tied by cemetery_id but without a Burial row
  fallback_soldiers = Soldier.where(cemetery_id: @cemetery.id)
  if @q.present?
    like = "%#{ActiveRecord::Base.sanitize_sql_like(@q)}%"
    fallback_soldiers = fallback_soldiers.where(
      "LOWER(COALESCE(first_name,'') || ' ' || COALESCE(last_name,'')) LIKE ?", like
    )
  end
  fallback_soldiers = fallback_soldiers.where.not(
    id: Burial.where(cemetery_id: @cemetery.id, participant_type: "Soldier").select(:participant_id)
  )

  # Map fallback soldiers to light pseudo-burial structs for the view
  soldier_as_burial = fallback_soldiers.map do |s|
    OpenStruct.new(
      id:            "soldier-#{s.id}",
      participant:   s,
      participant_id: s.id,
      participant_type: "Soldier",
      first_name:    s.first_name,
      middle_name:   s.middle_name,
      last_name:     s.last_name,
      birth_date:    s.try(:birth_date),
      birth_place:   [s.try(:birthcity), s.try(:birthstate), s.try(:birthcountry)].compact.join(", ").presence,
      death_date:    s.try(:death_date),
      death_place:   [s.try(:deathcity), s.try(:deathstate), s.try(:deathcountry)].compact.join(", ").presence,
      inscription:   nil,
      section:       nil,
      plot:          nil,
      marker:        nil,
      link_url:      nil,
      note:          nil
    )
  end

  @burials       = (real_burials + soldier_as_burial)
  @burials_count = @burials.size
end
end