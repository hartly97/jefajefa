class AwardsController < ApplicationController
  include AdminGuard
  before_action :set_award, only: [:show, :edit, :update, :destroy, :regenerate_slug]

  def index
  @battles = Award.order(:name)
  respond_to do |format|
    format.html
    format.json { render json: @awards.select(:id, :name) }
  end
end

  def show
    @award = Award.find_by!(slug: params[:id])
    @involvements = @award.involvements.includes(:participant)
  end
  
  def new 
    @award = Award.new 
  end
  
    def create
    @award = Award.new(award_params)
    if @award.save
      redirect_to @award, notice: "Award created."
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit 
    @award.citations.build if @award.citations.empty?
    ensure_nested_source_builds
  end
  
  def update
    @award = Award.find_by!(slug: params[:id])
    if @award.update(award_params)
      redirect_to @award, notice: "Award updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    @award = Award.find_by!(slug: params[:id]); @award.destroy
    redirect_to awards_path, notice: "Award deleted."
  end
  
  private
  
  def set_award
    @award = Award.find_by!(slug: params[:id])
  end

  def award_params 
    params.require(:award).permit(:name, :year, :country)
  end
end



