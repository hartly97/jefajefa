# app/controllers/soldiers_controller.rb
class SoldiersController < ApplicationController
  before_action :set_soldier, only: [:show, :edit, :update, :destroy, :regenerate_slug]
  before_action :require_admin!, only: [:regenerate_slug]
  before_action :load_sources, only: [:new, :edit]
  before_action :load_soldiers, only: [:index, :search]  

  # GET /soldiers
  def index
    @soldiers = Soldier.order(:last_name, :first_name).to_a
  end

  # GET /soldiers/:id

    def show
  @soldier = Soldier.includes(:cemetery, :awards, :citations => :source).find(@soldier.id)
end

  end

  # GET /soldiers/new
  def new
    @soldier = Soldier.new
    # build one row for each nested section so the form shows fields
    @soldier.awards.build
    @soldier.soldier_medals.build
    @soldier.citations.build
  end

  # GET /soldiers/:id/edit
  def edit
    # make sure at least one nested row exists for UX
    @soldier.awards.build        if @soldier.awards.empty?
    @soldier.soldier_medals.build if @soldier.soldier_medals.empty?
    @soldier.citations.build     if @soldier.citations.empty?
    @soldier.category_names ||= @soldier.categories.order(:name).pluck(:name).join(", ")
    @soldier.wars.build        if @soldier.wars.empty
    @soldier.battles.build        if @soldier.battles.empty
  end

  # POST /soldiers
  def create
    @soldier = Soldier.new(soldier_params)
    if @soldier.save
     
      redirect_to @soldier, notice: "Soldier created."
    else
      load_sources
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /soldiers/:id
  def update
    if @soldier.update(soldier_params)
     
      redirect_to @soldier, notice: "Soldier updated."
    else
      load_sources
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /soldiers/:id
  def destroy
    @soldier.destroy
    redirect_to soldiers_path, notice: "Soldier deleted."
  end

  # PATCH /soldiers/:id/regenerate_slug
  def regenerate_slug
    @soldier.regenerate_slug!
    redirect_to @soldier, notice: "Slug regenerated."
  end

  # GET /soldiers/search?q=...
  def search
    q = params[:q].to_s.strip
    scope = Soldier.order(:last_name, :first_name)
    @soldiers = q.blank? ? scope : scope.search_name(q)
    render :index
  end

  private

  # Try slug first, fall back to numeric id
  def set_soldier
    @soldier = Soldier.find_by(slug: params[:id]) || Soldier.find(params[:id])
  end

  # Only admins for certain actions
  def require_admin!
    unless current_user&.admin?
      redirect_back fallback_location: root_path, alert: "Admins only."
    end
  end

  # Needed by the citations partial for the Source dropdown
  def load_sources
    @sources = Source.order(:title)
  end

 
# def soldier_params
#   params.require(:soldier).permit(
#     :first_name, :last_name, 
#     :birthcity, :birthstate, :birthcountry,
#           :deathcity, :deathstate, :deathcountry,:cemetery_id,
#           { category_ids: [] } 
  
#     involvements_attributes: [:id, :involvable_id, :involvable_type, :_destroy],
#     soldier_medals_attributes: [:id, :medal_id, :_destroy],
#     citations_attributes: [
#       :id, :_destroy, :source_id,
#       :page, :pages, :folio, :column, :line_number, :record_number, :locator,
#       :image_url, :image_frame, :roll, :enumeration_district, :quote, :note],
#       source_attributes: [:id, :title, :author, :publisher, :year] # add your source fields
#      wars_attributes:
#         [:name,:url, :details, :repository, :link_url], 
#           awards_attributes: [:id, :name, :_destroy
#         ] 
#       }
#     )
#   end
# end
def soldier_params
  params.require(:soldier).permit(
    :first_name, :middle_name, :last_name,
    :birthcity, :birthstate, :birthcountry,
    :deathcity, :deathstate, :deathcountry,
    :cemetery_id,
    { category_ids: [] },
    # Awards (not medals)
      awards_attributes: [:id, :name, :country, :year, :note, :_destroy],
    # Medals (join with per-medal data)
    involvements_attributes: [:id, :involvable_type, :involvable_id, :role, :year, :note, :_destroy],
    soldier_medals_attributes: [:id, :medal_id, :year, :note, :_destroy],
    involvements_attributes:   [:id, :involvable_type, :involvable_id, :role, :year, :note, :_destroy],

    citations_attributes: [
      :id, :source_id, :_destroy,
      :page, :pages, :folio, :column, :line_number, :record_number, :locator,
      :image_url, :image_frame, :roll, :enumeration_district, :quote, :note,
      { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }
    ]
  )
end

