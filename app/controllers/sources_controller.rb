class SourcesController < ApplicationController
  before_action :set_source,    only: [:show, :edit, :update, :destroy, :regenerate_slug, :create_citation]
  before_action :require_admin, only: [:regenerate_slug]

  def index
    @sources = Source.order(:title)
  end

  def show
  end

  def new
     @source = Source
  end

  def edit
  end

  def create
    @source = Source.new(source_params)
    if @source.save
      redirect_to @source, notice: "Source created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @source.update(source_params)
      redirect_to @source, notice: "Source updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @source.destroy
    redirect_to sources_path, notice: "Source deleted."
  end

def regenerate_slug
  @source.regenerate_slug! if @source.respond_to?(:regenerate_slug!)
  redirect_back fallback_location: root_path, notice: "Slug regenerated."
end

def create_citation
  citable = find_citable!
  citation = citable.citations.find_or_initialize_by(source: @source)
  citation.assign_attributes(citation_params)
  if citation.save
    redirect_to citable, notice: "Citation added."
  else
    redirect_to citable, alert: citation.errors.full_messages.to_sentence
  end
end

  # Autocomplete endpoint for the Source picker
    def autocomplete
    q = params[:q].to_s.strip
    return render json: [] if q.length < 2

    results = Source
      .where("title ILIKE ?", "%#{q}%")
      .order(:title)
      .limit(20)
      .pluck(:id, :title)
      .map { |id, title| { id: id, title: title } }

    render json: results
  end
  


  private
  ALLOWED_CITABLES = %w[Article Soldier War Battle Cemetery Medal Award Census CensusEntry Source].freeze

  def find_citable!
    type = params[:citable_type].to_s
    id   = params[:citable_id].presence
    raise ActiveRecord::RecordNotFound, "Bad citable" unless ALLOWED_CITABLES.include?(type) && id
    type.constantize.find(id)
  end

  def set_source
    @source = Source.find_by(slug: params[:id]) || Source.find(params[:id])
  end

  def source_params
    base = [:title, :author, :publisher, :year, :url, :details, :pages, :common, :repository, :link_url]
    base << { category_ids: [] } if current_user&.admin?
    params.require(:source).permit(*base)
  end
end
def citation_params
    params.fetch(:citation, {}).permit(
      :pages, :folio, :page, :column, :line_number, :record_number,
      :image_url, :image_frame, :roll, :enumeration_district, :locator,
      :quote, :note
    )
  end
end
