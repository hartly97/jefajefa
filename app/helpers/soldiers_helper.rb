module SoldiersHelper
  def render_unit(soldier)
    return unless soldier.respond_to?(:unit) && soldier.unit.present?
    content_tag(:p) do
      content_tag(:strong, "Unit: ") + h(soldier.unit)
    end
  end

  def render_branch(soldier)
    return unless soldier.respond_to?(:branch_of_service) && soldier.branch_of_service.present?
    content_tag(:p) do
      content_tag(:strong, "Branch: ") + h(soldier.branch_of_service)
    end
  end

  # Include all relevant category types for soldiers
  def soldier_badge_categories(soldier)
    soldier.categories_of_types(:war, :battle, :medal, :award, :cemetery)
  end
end
