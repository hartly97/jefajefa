class BattlesController < ApplicationController
  include AdminGuard

  before_action :set_battle, only: [:show, :edit, :update, :destroy, :regenerate_slug]
  before_action :set_sources, only: [:new, :edit]
  before_action :ensure_nested_source_builds, only: [:new, :edit]

  def index
  @battles = Battle.order(:name)
  respond_to do |format|
    format.html
    format.json { render json: @battles.select(:id, :name) }
  end
end

  def show
    @involvements = @battle.involvements.includes(:participant)
  end

  def new
    @battle = Battle.new
    @battle.citations.build
  end

  def create
    @battle = Battle.new(battle_params)
    if @battle.save
      redirect_to @battle, notice: "Battle created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @battle.citations.build if @battle.citations.empty?
  end

  def update
    if @battle.update(battle_params)
      redirect_to @battle, notice: "Battle updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @battle.destroy
    redirect_to battles_path, notice: "Battle deleted."
  end

  def regenerate_slug
    @battle.regenerate_slug!
    redirect_to @battle, notice: "Slug regenerated."
  end

  private

  def set_battle
    @battle = Battle.includes(involvements: :participant)
                    .find_by(slug: params[:id]) || Battle.find(params[:id])
  end

  def set_sources
    @sources = Source.order(:title)
  end

  def ensure_nested_source_builds
    (@battle || @record)&.citations&.each { |c| c.build_source if c.source.nil? }
  end

  # Adjust fields if your schema differs
  def battle_params
    params.require(:battle).permit(
      :name, :date, :location, :war_id, :description, :notes,
      citations_attributes: [
        :id, :_destroy, :source_id,
        :pages, :quote, :note,
        :volume, :issue, :folio, :page, :column, :line_number, :record_number,
        :image_url, :image_frame, :roll, :enumeration_district, :locator,
        { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }
      ],
      involvements_attributes: [
        :id, :participant_id, :participant_type, :role, :year, :note, :_destroy
      ]
    )
  end
end
