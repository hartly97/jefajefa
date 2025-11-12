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
  # soldier_as_burial = fallback_soldiers.map do |s|
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
  # Optional: for your AJAX soldier links panel (not used for burials)
# panel list (if you’re still showing it)
  @involvements = @cemetery.involvements.includes(:participant).order(:year, :id)
end
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

  def set_cemetery
    @cemetery =
      Cemetery
        .includes(:burials, involvements: :participant) # safe preload
        .find_by(slug: params[:id]) || Cemetery.find(params[:id])
        Cemetery
        .includes(:burials, involvements: :participant)
        .find_by(id: params[:id])
            # Helpful 404 instead of nil
    raise ActiveRecord::RecordNotFound, "Cemetery not found" unless @cemetery
  end

  def set_sources
    @sources = Source.order(:title)
  end

  def ensure_nested_source_builds
    (@cemetery || @record)&.citations&.each { |c| c.build_source if c.source.nil? }
  end


  def cemetery_params
    params.require(:cemetery).permit(
      :name, :city, :state, :country, :note,
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

