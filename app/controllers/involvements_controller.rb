class InvolvementsController < ApplicationController
  def create
    inv_params = params.require(:involvement).permit(:participant_type, :participant_id, :involvable_type, :involvable_id, :role, :year, :note)
    @involvement = Involvement.find_or_initialize_by(
      participant_type: inv_params[:participant_type],
      participant_id:   inv_params[:participant_id],
      involvable_type:  inv_params[:involvable_type],
      involvable_id:    inv_params[:involvable_id],
    )
    @involvement.role = inv_params[:role]
    @involvement.year = inv_params[:year]
    @involvement.note = inv_params[:note]
    if @involvement.save
      redirect_back fallback_location: root_path, notice: "Involvement added."
    else
      redirect_back fallback_location: root_path, alert: @involvement.errors.full_messages.to_sentence
    end
  end

  def destroy
    @involvement = Involvement.find(params[:id])
    @involvement.destroy
    redirect_back fallback_location: root_path, notice: "Involvement removed."
  end
end
