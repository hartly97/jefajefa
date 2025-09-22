module MonthName
  def abbr_month_name(n)
    n = n.to_i
    return nil unless (1..12).include?(n)
    Date::ABBR_MONTHNAMES[n]
  end
  def month_name(n)
    n = n.to_i
    return nil unless (1..12).include?(n)
    Date::MONTHNAMES[n]
  end
end
