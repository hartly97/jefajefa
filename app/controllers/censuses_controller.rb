class CensusesController < ApplicationController
  before_action :set_census, only: %i[show edit update destroy regenerate_slug]
  # Include create/update so re-rendered forms still have @sources
  before_action :load_sources_for_citations, only: %i[new edit create update]

  # GET /censuses
  # Filters: year, district, piece, folio, page, q (district/subdistrict/place/slug)
  def index
    @years     = Census.distinct.order(year: :desc).pluck(:year)
    @districts = Census.where.not(district: [nil, ""]).distinct.order(:district).pluck(:district)

    scope = Census.all
    scope = scope.where(year: params[:year])           if params[:year].present?
    scope = scope.where(district: params[:district])   if params[:district].present?
    scope = scope.where(piece: params[:piece])         if params[:piece].present?
    scope = scope.where(folio: params[:folio])         if params[:folio].present?
    scope = scope.where(page: params[:page])           if params[:page].present?

    if (q = params[:q]).present?
      q = q.strip.downcase
      scope = scope.where(
        "LOWER(COALESCE(district,'') || ' ' || COALESCE(subdistrict,'') || ' ' || COALESCE(place,'')) LIKE :q
         OR LOWER(COALESCE(slug,'')) LIKE :q",
        q: "%#{q}%"
      )
    end

    @censuses = scope.order(year: :desc, district: :asc, piece: :asc, folio: :asc, page: :asc).limit(500)
  end

  # GET /censuses/new
  def new
    @census = Census.new
    c = @census.citations.build
    c.build_source
  end

  # POST /censuses
  def create
    @census = Census.new(census_params)
    if @census.save
      redirect_to @census, notice: "Census created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /censuses/:id/edit
  def edit
    @census.citations.each { |c| c.build_source unless c.source }
  end

  # PATCH/PUT /censuses/:id
  def update
    if @census.update(census_params)
      redirect_to @census, notice: "Census updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /censuses/:id
  def destroy
    @census.destroy
    redirect_to censuses_path, notice: "Census deleted."
  end

  # GET /censuses/:id
  def show
    if params[:householdid].present?
      @entries = @census.census_entries.where(householdid: params[:householdid]).order(:linenumber)
    else
      @entries = @census.census_entries.order(:householdid, :linenumber)
    end
  end

  private

  def set_census
    @census = Census.find_by(id: params[:id]) || Census.find_by(slug: params[:id])
    unless @census
      redirect_to censuses_path, alert: "Census not found."
    end
  end

  def census_params
    params.require(:census).permit(
      :country, :year, :district, :subdistrict, :place, :piece, :folio, :page, :booknumber,:slug,
      :external_image_url, :external_image_caption, :external_image_credit,{ category_ids: [] },
      citations_attributes: [
        :id, :source_id, :pages, :quote, :note, :volume, :issue, :folio, :page, :column,
        :line_number, :record_number, :image_url, :image_frame, :roll, :enumeration_district,
        :locator, :_destroy,
        { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }
      ]
    )
  end

  def load_sources_for_citations
    @sources = Source.order(:title)
  end
end
