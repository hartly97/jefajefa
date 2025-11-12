class BurialsController < ApplicationController
  before_action :set_cemetery, only: [:index, :new, :create]
  before_action :set_burial,   only: [:show, :edit, :update, :destroy]

  def index
    @burials = @cemetery.burials.order(:last_name, :first_name, :id)
  end

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

  def show
   end
  def edit
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
      :inscription, :section, :plot, :marker, :link_url, :note,
      :participant_type, :participant_id
    )
  end

  def seed_names_from_participant(b)
    return unless b.participant_type == "Soldier" && b.participant_id.present?
    s = Soldier.find_by(id: b.participant_id)
    return unless s
    b.first_name = s.first_name if b.first_name.blank?
    b.last_name  = s.last_name  if b.last_name.blank?
  end
end
