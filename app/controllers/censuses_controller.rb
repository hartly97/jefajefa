class CensusesController < ApplicationController
  before_action :load_sources_for_citations, only: [:new, :edit]

  # GET /censuses
  # Filters: year, district, piece, folio, page, q (free text across district/place)
def index
    @years     = Census.distinct.order(year: :desc).pluck(:year)
    @districts = Census.distinct.order(:district).where.not(district: [nil, ""]).pluck(:district)

    scope = Census.all
    scope = scope.where(year: params[:year].to_i) if params[:year].present?
    scope = scope.where(district: params[:district]) if params[:district].present?
    scope = scope.where(piece: params[:piece]) if params[:piece].present?
    scope = scope.where(folio: params[:folio]) if params[:folio].present?
    scope = scope.where(page: params[:page]) if params[:page].present?

    if (q = params[:q]).present?
      q = q.strip
      scope = scope.where(
         "LOWER(COALESCE(district,'') || ' ' || COALESCE(subdistrict,'') || ' ' || COALESCE(place,'')) LIKE ?",
  "%#{q.downcase}%"
      )
    end

    @censuses = scope.order(year: :desc, district: :asc, piece: :asc, folio: :asc, page: :asc).limit(500)
end

 
def show
    unless @census
      redirect_to censuses_path, alert: "Census not found."
      return
    end

    @entries =
      if @census.householdid.present?
        Census.where(householdid: @census.householdid).order(:linenumber)
      else
        Census.where(id: @census.id)
      end
  end

  private

  def set_census
    # If you don't have slugs for Census, look up by id first.
    @census = Census.find_by(id: params[:id])
    # If you *do* have slugs, keep this fallback:
    @census ||= Census.find_by(slug: params[:id])
  end
  
  def cemetery params
  params.require(:census).permit(
      :title, :volume, :note, :year, :place, :subdistrict, :folio, :page, :external_image_url, :external_image_caption, :external_image_credit)
end

def load_sources_for_citations = @sources = Source.order(:title)
end 

