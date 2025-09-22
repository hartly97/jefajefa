class WarsController < ApplicationController
  before_action :set_war,      only: [:show, :edit, :update, :destroy, :regenerate_slug]
  before_action :set_sources,  only: [:new, :edit]
  before_action :ensure_nested_source_builds, only: [:new, :edit]

  def index
   @wars = War. order(:name)
  end

  def new
    @war = War.new
    @war.citations.build
  end

  def edit
    @war.citations.build if @war.citations.empty?
  end
  
  def show
    @involvements = @war.involvements.includes(:participant)
  end

 def create
    @war = War.new(war_params)
    if @war.save
      redirect_to @war, notice: "War created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # /wars/:id
  def update
    if @war.update(war_params)
      redirect_to @war, notice: "War updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
def destroy
    @war.destroy
    redirect_to wars_path, notice: "War deleted."
  end

  def set_sources
    @sources = Source.order(:title)
  end

  def ensure_nested_source_builds
    (@war || @record)&.citations&.each { |c| c.build_source if c.source.nil? }
  end
end
# app/controllers/wars_controller.rb
class WarsController < ApplicationController
  before_action :set_war, only: [:show, :edit, :update, :destroy, :regenerate_slug]

  # GET /wars
  def index
    @wars = War.order(:name)
  end

  # GET /wars/:id
  def show
    @involvements = @war.involvements.includes(:participant)
  end

  # GET /wars/new
  def new
    @war = War.new
    @war.citations.build
  end

  # GET /wars/:id/edit
  def edit
    @war.citations.build if @war.citations.empty?
  end

  # POST /wars
  def create
    @war = War.new(war_params)
    if @war.save
      redirect_to @war, notice: "War created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /wars/:id
  def update
    if @war.update(war_params)
      redirect_to @war, notice: "War updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /wars/:id
  def destroy
    @war.destroy
    redirect_to wars_path, notice: "War deleted."
  end

  # PATCH /wars/:id/regenerate_slug
  def regenerate_slug
    @war.regenerate_slug!
    redirect_to @war, notice: "Slug regenerated."
  end

  private
def set_sources
  @sources = Source.order(:title)
end

  def set_war
    @war = War.find_by(slug: params[:id]) || War.find(params[:id])
  end

  def war_params
    params.require(:war).permit(
      :name, :start_year, :end_year, :note,
      { category_ids: [] },
      citations_attributes: [
        :id, :source_id, :pages, :quote, :note, :_destroy,
        { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }
      ],
      involvements_attributes: [
        :id, :involvable_type, :involvable_id, :role, :year, :note, :_destroy
      ]
    )
  end
end
