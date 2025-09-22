# class MedalsController < ApplicationController
#   include AdminGuard
#   before_action :set_medal, only: [:show, :edit, :update, :destroy,:regenerate_slug]

#   def index
#     @medals = Medal Medal.order(:name)
#   end
  
#   def show
#     @medal = Medal.find_by!(slug: params[:id])
#     @involvements = @medal.involvements.includes(:participant)
#   end
  
#   def new 
#     @medal = Medal.new 
#   end
  
#     def create
#     @medal = Medal.new(medal_params)
#     if @medal.save
#       redirect_to @medal, notice: "Medal created."
#     else
#       render :new, status: :unprocessable_entity
#     end
#   end
  
#   def edit 
#     @medal.citations.build if @medal.respond_to?(:citations) && @medal.citations.empty?
#     ensure_nested_source_builds if respond_to?(:ensure_nested_source_builds, true)
#   end
  
#   def update
#     @medal = Medal.find_by!(slug: params[:id])
#     if @medal.update(medal_params)
#       redirect_to @medal, notice: "Medal updated."
#     else
#       render :edit, status: :unprocessable_entity
#     end
#   end
#   def destroy
#     @medal = Medal.find_by!(slug: params[:id]); @medal.destroy
#     redirect_to medals_path, notice: "Medal deleted."
#   end
  
#   private
#     set medal 
#       @medal = Medal.find_by!(slug: params[:id])
#     end
  
#   def medal_params
#     params.require(:medal).permit(:name, :year)
#   end



# app/controllers/medals_controller.rb
class MedalsController < ApplicationController
  include AdminGuard
  before_action :set_medal, only: [:show, :edit, :update, :destroy, :regenerate_slug]

  def index
    @medals = Medal.order(:name)
  end

  def show
    # If you need it:
    @involvements = @medal.involvements.includes(:participant)
  end

  def new
    @medal = Medal.new
  end

  def create
    @medal = Medal.new(medal_params)
    if @medal.save
      redirect_to @medal, notice: "Medal created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Only if Medal has citations via Citable
    @medal.citations.build if @medal.respond_to?(:citations) && @medal.citations.empty?
    ensure_nested_source_builds if respond_to?(:ensure_nested_source_builds, true)
  end

  def update
    if @medal.update(medal_params)
      redirect_to @medal, notice: "Medal updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @medal.destroy
    redirect_to medals_path, notice: "Medal deleted."
  end

  def regenerate_slug
    @medal.regenerate_slug!
    redirect_to @medal, notice: "Slug regenerated."
  end

  private

  def set_medal
    @medal = Medal.find_by!(slug: params[:id])
  end

  def medal_params
    params.require(:medal).permit(:name, :year, :note)
  end
end
