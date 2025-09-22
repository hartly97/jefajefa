class BattlesController < ApplicationController
   include AdminGuard
   before_action :set_battle, only: [:show, :edit, :update, :destroy, :regenerate_slug]
  def index
    @battles = Battle.order(:name).page(params[:page])
     @battles = maybe_page(Battle.order(:name))
  end
  def show
    @battle = Battle.find_by!(slug: params[:id])
    @involvements = @battle.involvements.includes(:participant)
  end
  def new
     @battle = Battle.new
     @battle.citations.build
 end
  def create
    @battle = Battle.new(battle_params)
   if battle.save
    
      redirect_to @battle, notice: "battle created."
    else
      render :new, status: :unprocessable_entity
    end
  end
  def edit
     @battle = Battle.find_by!(slug: params[:id])
      @battle.citations.build if @battle.citations.empty?
    end
  def update
    @battle = Battle.find_by!(slug: params[:id])
    if @battle.update(battle_params)
     
      redirect_to @battle, notice: "Battle updated."
    else
      render :edit, status: :unprocessable_entity
  end
  def destroy
    @battle = Battle.find_by!(slug: params[:id]); @battle.destroy
    redirect_to battles_path, notice: "Battle deleted."
  end
  def regenerate_slug
    @war.regenerate_slug!
    redirect_to @war, notice: "Slug regenerated."
  end
  private
  def battle_params
     params.require(:battle).permit(:name, :date)
    def war_params
    params.require(:battle).permit(
      :name,:date)
      { category_ids: [] },  # admin-only multiselect; harmless if empty
      citations_attributes: [
        :id, :source_id, :pages, :quote, :note, :_destroy,
        { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }
      ],
      involvements_attributes: [
        :id, :involvable_type, :involvable_id, :role, :year, :note, :_destroy
      ]
    
    end
end
end