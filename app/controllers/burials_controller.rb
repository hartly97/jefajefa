# app/controllers/burials_controller.rb
class BurialsController < ApplicationController
  before_action :set_cemetery, only: [:index, :new, :create]
  before_action :set_burial,   only: [:show, :edit, :update, :destroy]

  def index
    @burials = @cemetery.burials.order(:last_name, :first_name, :id)
     @burials = Burial.includes(:cemetery).order(:last_name, :first_name).limit(200)
    @total_count = Burial.count
  
    @q          = params[:q].to_s.strip
    @cemetery_id = params[:cemetery_id].presence
    @per_page   = (params[:per_page].presence || 50).to_i.clamp(1, 200)
    @page       = (params[:page].presence || 1).to_i.clamp(1, 10_000)
    offset      = (@page - 1) * @per_page

    scope = Burial.includes(:cemetery)
    scope = scope.where(cemetery_id: @cemetery_id) if @cemetery_id
    scope = scope.q_search(@q)

    @total_count = scope.count
    @burials     = scope.order(:last_name, :first_name).limit(@per_page).offset(offset)
    @has_next    = (@page * @per_page) < @total_count

    @cemeteries  = Cemetery.order(:name) # for the dropdown
  end

  def show
  @burial = Burial.find(params[:id])
  end
  
  def edit; end

  def new
    @burial = @cemetery.burials.build
  end

  def create
    @burial = @cemetery.burials.build(burial_params)
    seed_names_from_participant(@burial)
    if @burial.save
      redirect_to @cemetery, notice: "Burial added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @burial.update(burial_params)
      redirect_to @burial, notice: "Burial updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    cemetery = @burial.cemetery
    @burial.destroy
    redirect_to cemetery, notice: "Burial deleted."
  end

  private

  def set_cemetery
    @cemetery = Cemetery.find(params[:cemetery_id])
  end

  def set_burial
    @burial = Burial.find(params[:id])
  end

  def burial_params
    params.require(:burial).permit(
      :first_name, :middle_name, :last_name,
      :birth_date, :birth_place, :death_date, :death_place,
      :inscription, :section, :plot, :marker, :link_url, :note, :slug,
      :participant_type, :participant_id,
      { category_ids: [] }
    )
  end

  def seed_names_from_participant(b)
    return unless b.participant_type == "Soldier" && b.participant_id.present?
    if (s = Soldier.find_by(id: b.participant_id))
      b.first_name = s.first_name if b.first_name.blank?
      b.last_name  = s.last_name  if b.last_name.blank?
    end
  end
end
