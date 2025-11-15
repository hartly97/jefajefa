class SoldiersController < ApplicationController
  before_action :set_soldier,  only: %i[show edit update destroy regenerate_slug]
  before_action :load_sources, only: %i[new edit]

  def index
    @q = params[:q].to_s.strip
    scope = Soldier.order(:last_name, :first_name)
    scope = scope.search_name(@q) if @q.present?

    @total_count = scope.count
    @total_pages = (@total_count.to_f / page_size).ceil
    @soldiers    = scope.limit(page_size).offset((current_page - 1) * page_size)
    @has_next    = current_page < @total_pages
  end

  def show; end

  def new
    @soldier = Soldier.new
    build_nested(@soldier)
  end

  def edit
    build_nested(@soldier)
  end

  def create
    @soldier = Soldier.new(soldier_params)
    if @soldier.save
      redirect_to @soldier, notice: "Soldier created."
    else
      load_sources
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @soldier.update(soldier_params)
      redirect_to @soldier, notice: "Soldier updated."
    else
      load_sources
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @soldier.destroy
    redirect_to soldiers_path, notice: "Soldier deleted."
  end

  def regenerate_slug
    @soldier.regenerate_slug!
    redirect_to @soldier, notice: "Slug regenerated."
  end

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

  def set_soldier
    base = Soldier.includes(:cemetery, :awards, { citations: :source }, :categories, { involvements: :involvable })
    @soldier = base.find_by(slug: params[:id]) || base.find(params[:id])
  end

  def page_size     = (params[:per_page].presence || 30).to_i.clamp(1, 200)
  def current_page  = (params[:page].presence || 1).to_i.clamp(1, 10_000)
  def load_sources  = @sources = Source.order(:title)

  def build_nested(s)
    s.awards.build         if s.awards.empty?
    s.soldier_medals.build if s.soldier_medals.empty?
    s.citations.build      if s.citations.empty?
  end


  def soldier_params
    params.require(:soldier).permit(
      :first_name, :middle_name, :last_name,
      :birth_date, :birthcity, :birthstate, :birthcountry,
      :death_date, :deathcity, :deathstate, :deathcountry, :deathplace,
      :cemetery_id, :unit, :branch_of_service,
      :first_enlisted_start_date, :first_enlisted_end_date, :first_enlisted_place,
      :slug,
      { category_ids: [] },
      awards_attributes: [:id, :name, :country, :year, :note, :_destroy],
      soldier_medals_attributes: [:id, :medal_id, :year, :note, :_destroy],
      citations_attributes: [
        :id, :source_id, :_destroy,
        :page, :pages, :folio, :column, :line_number, :record_number, :locator,
        :image_url, :image_frame, :roll, :enumeration_district, :quote, :note,
        { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }
      ]
    )
  end
end
