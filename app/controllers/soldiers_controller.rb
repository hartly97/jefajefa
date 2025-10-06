# app/controllers/soldiers_controller.rb
class SoldiersController < ApplicationController
  before_action :set_soldier,  only: %i[show edit update destroy regenerate_slug]
  before_action :load_sources, only: %i[new edit]

  # GET /soldiers
  # app/controllers/soldiers_controller.rb  (index action only)
def index
  # @q = params[:q].to_s.strip
  # scope = Soldier.order(:last_name, :first_name)
  # scope = scope.search_name(@q) if @q.present?

  # # counts for Last/summary
  # @total_count = scope.count
  # @total_pages = (@total_count.to_f / page_size).ceil

  # offset = (current_page - 1) * page_size
  # @soldiers = scope.limit(page_size).offset(offset)

  # @has_next = current_page < @total_pages

  def index
  @q = params[:q].to_s.strip
  scope = Soldier.order(:last_name, :first_name)
  scope = scope.search_name(@q) if @q.present?

  @total_count = scope.count
  @total_pages = (@total_count.to_f / page_size).ceil

  offset = (current_page - 1) * page_size
  @soldiers = scope.limit(page_size).offset(offset)
  @has_next  = current_page < @total_pages

  # (keep your medal_categories block as-is below this)
  @medal_categories = begin
    parent = Category.where("lower(name) = ?", "medals").first
    if parent && Category.column_names.include?("parent_id")
      Category.where(parent_id: parent.id).order(:name)
    elsif parent && parent.respond_to?(:children)
      parent.children.order(:name)
    else
      Category.where("name ILIKE ?", "%medal%").order(:name)
    end
  rescue
    []
  end
end


    # Medal category list for a dropdown (best-effort, safe if structure varies)
    @medal_categories = begin
      parent = Category.where("lower(name) = ?", "medals").first
      if parent && Category.column_names.include?("parent_id")
        Category.where(parent_id: parent.id).order(:name)
      elsif parent && parent.respond_to?(:children)
        parent.children.order(:name)
      else
        Category.where("name ILIKE ?", "%medal%").order(:name)
      end
    rescue
      []
    end
  end

  # GET /soldiers/:id
  def show
    @soldier = Soldier
      .includes(:cemetery, :awards, { citations: :source }, :categories)
      .find(@soldier.id)
  end

  # GET /soldiers/new
  def new
    @soldier = Soldier.new
    @soldier.awards.build
    @soldier.soldier_medals.build
    @soldier.citations.build
  end

  # GET /soldiers/:id/edit
  def edit
    @soldier.awards.build         if @soldier.awards.empty?
    @soldier.soldier_medals.build if @soldier.soldier_medals.empty?
    @soldier.citations.build      if @soldier.citations.empty?
    # If you use this virtual attr in the form:
    @soldier.category_names ||= @soldier.categories.order(:name).pluck(:name).join(", ") if @soldier.respond_to?(:category_names)
    # Note: wars/battles are selected via category_ids in your form, so no builds here.
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

  # GET /soldiers/search.json?q=...
  def search
    q = params[:q].to_s.strip
    scope = Soldier.order(:last_name, :first_name)
    scope = Soldier.search_name(q).order(:last_name, :first_name) if q.present? && Soldier.respond_to?(:search_name)
    render json: scope.limit(10).map { |s|
      base = (s.respond_to?(:soldier_name) && s.soldier_name.presence) ||
             [s.try(:first_name), s.try(:last_name)].compact.join(" ").presence ||
             s.try(:name) || s.try(:title) || s.try(:slug) || "Soldier ##{s.id}"
      { id: s.id, label: "#{base} (##{s.id})" }
    }
  end

  private

  # Try slug, fallback to id
  def set_soldier
    @soldier = Soldier.find_by(slug: params[:id]) || Soldier.find(params[:id])
  end

  # def page_size
  #   (params[:per_page].presence || 50).to_i.clamp(1, 200)
  # end

  # def current_page
  #   (params[:page].presence || 1).to_i.clamp(1, 10_000)
  # end

  def page_size
  (params[:per_page].presence || 30).to_i.clamp(1, 200)
end

def current_page
  (params[:page].presence || 1).to_i.clamp(1, 10_000)
end

  # Only admins for certain actions (not wired yet, keep if you’ll use it)
  def require_admin!
    redirect_back fallback_location: root_path, alert: "Admins only." unless current_user&.admin?
  end

  # For the citations dropdown/partials
  def load_sources
    @sources = Source.order(:title)
  end

  def soldier_params
    params.require(:soldier).permit(
      :first_name, :middle_name, :last_name,
      :birth_date, :birthcity, :birthstate, :birthcountry,
      :death_date, :deathcity, :deathstate, :deathcountry, :deathplace,
      :cemetery_id,
      { category_ids: [] },

      # Awards (not medals)
      awards_attributes: [:id, :name, :country, :year, :note, :_destroy],

      # Medals with bridge model
      soldier_medals_attributes: [:id, :medal_id, :year, :note, :_destroy],

      # Involvements (if you edit these here)
      involvements_attributes: [:id, :involvable_type, :involvable_id, :role, :year, :note, :_destroy],

      # Citations (+ nested source)
      citations_attributes: [
        :id, :source_id, :_destroy,
        :page, :pages, :folio, :column, :line_number, :record_number, :locator,
        :image_url, :image_frame, :roll, :enumeration_district, :quote, :note,
        { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }
      ]
    )
  end
end
