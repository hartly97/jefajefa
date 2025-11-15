class CemeteriesController < ApplicationController
  before_action :set_cemetery, only: [:show, :edit, :update, :destroy, :regenerate_slug]
  
  before_action :set_sources,  only: [:new, :edit]
  
  before_action :ensure_nested_source_builds, only: [:new, :edit]

  def index
    @cemeteries = Cemetery.order(:name)
    respond_to do |format|
      format.html
      format.json { render json: @cemeteries.select(:id, :name) }
    end
  end
 
  def show
  @cemetery = Cemetery.find_by(slug: params[:id]) || Cemetery.find(params[:id])
  @burials  = @cemetery.burials.order(:last_name, :first_name).limit(200)
  @total_count = @cemetery.burials.count

  @q = params[:q].to_s.strip.downcase

  # 1) Real burials  NO join on polymorphic participant
  burials_scope = @cemetery.burials

  if @q.present?
    like = "%#{ActiveRecord::Base.sanitize_sql_like(@q)}%"

    # Match either burials own name fields OR the linked Soldiers name
    burials_scope = burials_scope.where(<<~SQL, q: like)
      LOWER(COALESCE(burials.first_name,'') || ' ' || COALESCE(burials.last_name,'')) LIKE :q
      OR (
        burials.participant_type = 'Soldier'
        AND EXISTS (
          SELECT 1
          FROM soldiers
          WHERE soldiers.id = burials.participant_id
            AND LOWER(COALESCE(soldiers.first_name,'') || ' ' || COALESCE(soldiers.last_name,'')) LIKE :q
        )
      )
    SQL
  end

  #  Preload (separate query), do NOT join
  real_burials = burials_scope.preload(:participant).to_a

  # 2) Fallback: Soldiers tied by cemetery_id but without a Burial row
  fallback_soldiers = Soldier.where(cemetery_id: @cemetery.id)
  fallback_soldiers = fallback_soldiers.where(
  "LOWER(COALESCE(first_name,'') || ' ' || COALESCE(last_name,'')) LIKE ?",
  like
) if @q.present?
fallback_soldiers = fallback_soldiers.where.not(
  id: Burial.where(cemetery_id: @cemetery.id, participant_type: "Soldier").select(:participant_id)
)
  soldier_as_burial = fallback_soldiers.map do |s|
  OpenStruct.new(
    id:               "soldier-#{s.id}",
    participant:      s,
    participant_id:   s.id,
    participant_type: "Soldier",
    first_name:       s.first_name,
    middle_name:      s.middle_name,
    last_name:        s.last_name,
    birth_date:       s.try(:birth_date),
    birth_place:      [s.try(:birthcity), s.try(:birthstate), s.try(:birthcountry)].compact.join(", ").presence,
    death_date:       s.try(:death_date),
    death_place:      [s.try(:deathcity), s.try(:deathstate), s.try(:deathcountry)].compact.join(", ").presence,
    inscription:      nil, section: nil, plot: nil, marker: nil, link_url: nil, note: nil
  )
end

#  Split for the view
real_soldier_burials = real_burials.select { |b| b.participant_type == "Soldier" }
other_real_burials   = real_burials.reject { |b| b.participant_type == "Soldier" }

# Soldiers section = real soldier burials + fallback soldiers
@soldier_burials = real_soldier_burials + soldier_as_burial

# Other section = all non-soldier real burials
@other_burials   = other_real_burials

# Optional counts
@soldier_burials_count = @soldier_burials.size
@other_burials_count   = @other_burials.size



  # Optional panel list, now safe (no polymorphic join)
  @involvements = @cemetery.involvements.includes(:participant).order(:year, :id)
end



  def new
    @cemetery = Cemetery.new
    @cemetery.citations.build
  end

  def create
    @cemetery = Cemetery.new(cemetery_params)
    if @cemetery.save
      redirect_to @cemetery, notice: "Cemetery created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @cemetery.citations.build if @cemetery.citations.empty?
  end

  def update
    if @cemetery.update(cemetery_params)
      redirect_to @cemetery, notice: "Cemetery updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @cemetery.destroy
    redirect_to cemeteries_path, notice: "Cemetery deleted."
  end

  def regenerate_slug
    @cemetery.regenerate_slug!
    redirect_to @cemetery, notice: "Slug regenerated."
  end

private
def set_sources
    @sources = Source.order(:title)
  end

  def ensure_nested_source_builds
    (@cemetery || @record)&.citations&.each { |c| c.build_source if c.source.nil? }
  end

 def set_cemetery
    preload = { burials: :participant, involvements: :participant }
    @cemetery =
      Cemetery.includes(preload).find_by(slug: params[:id]) ||
      Cemetery.includes(preload).find_by(id: params[:id])
    raise ActiveRecord::RecordNotFound, "Cemetery not found" unless @cemetery
  end
 

  def cemetery_params
    params.require(:cemetery).permit(
      :name, :city, :state, :country, :note,:slug,
      { category_ids: [] },
      citations_attributes: [
        :id, :_destroy, :source_id,
        :page, :pages, :folio, :column, :line_number, :record_number, :locator,
        :image_url, :image_frame, :roll, :enumeration_district, :quote, :note,
        { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }
      ]
      # NOTE: no nested involvements here; those are managed via the panel (AJAX)
    )
  end 
end
