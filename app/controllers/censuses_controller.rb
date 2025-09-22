class CensusesController < ApplicationController
  before_action :load_sources_for_citations, only: [:new, :edit]
def load_sources_for_citations = @sources = Source.order(:title)

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

  # GET /censuses/:id
  def show
    @census = Census.find_by!(slug: params[:id])
    @entries = @census.census_entries.order(:householdid, :household_position, :lastname, :firstname)
  end
end
