class WarsController < ApplicationController
  before_action :set_war,                      only: [:show, :edit, :update, :destroy, :regenerate_slug]
  before_action :set_sources,                  only: [:new, :edit]
  before_action :ensure_nested_source_builds,  only: [:new, :edit]


  def index
  @wars = War.order(:name)
  respond_to do |format|
    format.html
    format.json { render json: @wars.select(:id, :name) }
  end
end

  def new
    @war = War.new
    @war.citations.build
  end

  def edit
    @war.citations.build if @war.citations.empty?
  end

  

  def show
  @war = War.includes(citations: :source).find(params[:id])
  @involvements = @war.involvements.includes(:participant).order(:year, :id)
end



  def create
    @war = War.new(war_params)
    if @war.save
      redirect_to @war, notice: "War created."
    else
      render :new, status: :unprocessable_entity
    end
  end

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

  def regenerate_slug
    @war.regenerate_slug!
    redirect_to @war, notice: "Slug regenerated."
  end

  private

  def set_war
    @war = War.includes(involvements: :participant)
              .find_by(slug: params[:id]) || War.find(params[:id])
  end

  def set_sources
    @sources = Source.order(:title)
  end

  def ensure_nested_source_builds
    (@war || @record)&.citations&.each { |c| c.build_source if c.source.nil? }
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
        :id, :participant_id, :participant_type, :role, :year, :note, :_destroy
      ]
    )
  end
end
