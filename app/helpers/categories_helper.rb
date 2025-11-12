module CategoriesHelper
  # Bootstrap color per type
  def category_badge_class(cat)
    case cat.category_type.to_s
    when "war"      then "text-bg-primary"
    when "battle"   then "text-bg-secondary"
    when "medal"    then "text-bg-success"
    when "award"    then "text-bg-warning"
    when "cemetery" then "text-bg-info"
    else                 "text-bg-light"
    end
  end

  # Optional Bootstrap Icons (only shown if you have them)
  def category_badge_icon(cat)
    case cat.category_type.to_s
    when "war"      then "bi-flag"
    when "battle"   then "bi-shield"
    when "medal"    then "bi-award"
    when "award"    then "bi-trophy"
    when "cemetery" then "bi-geo-alt"
    else                 nil
    end
  end

  # Tooltip text / accessible label
  def category_badge_title(cat)
    type = cat.category_type.to_s.titleize.presence || "Category"
    "#{type}: #{cat.name}"
  end
end
