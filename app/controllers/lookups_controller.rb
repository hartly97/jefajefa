class LookupsController < ApplicationController
  # GET /lookups/citables?type=Soldier&q=smith
  
  def citables
    type = params[:type].to_s
    q    = params[:q].to_s.strip
    klass = type.safe_constantize
    return render json: [] unless klass && %w[Article Soldier Cemetery War Battle Medal].include?(type)

    pattern = "%%%s%%" % q
    records = case type
      when "Article"
        klass.where("title ILIKE ?", pattern).order(:title).limit(10)
      when "Soldier"
        klass.where("COALESCE(first_name,'') || ' ' || COALESCE(middle_name,'') || ' ' || COALESCE(last_name,'') ILIKE ?", pattern).order(:last_name, :first_name).limit(10)
      else
        # Cemetery, War, Battle, Medal use `name`
        klass.where("name ILIKE ?", pattern).order(:name).limit(10)
    end

    json = records.map do |r|
      label =
        if r.respond_to?(:title) && r.title.present?
          r.title
        elsif r.respond_to?(:soldier_name) && r.soldier_name.present?
          r.soldier_name
        elsif r.respond_to?(:name) && r.name.present?
          r.name
        else
          r.slug
        end
      { id: r.id, label: "#{label} (#%d)" % r.id }
    end
    render json: json
  end
end
