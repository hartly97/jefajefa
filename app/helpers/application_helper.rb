module ApplicationHelper
  def category_badge_class(category)
    case category&.category_type.to_s
    when "location" then "bg-success"
    when "source"   then "bg-secondary"
    when "topic"    then "bg-primary"
    else                 "bg-info"
    end
  end
end
