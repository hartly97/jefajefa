class InvolvementsController < ApplicationController
  protect_from_forgery with: :exception

  def create
    attrs = involvement_params.merge(participant_type: "Soldier")
    inv = Involvement.find_or_initialize_by(
      participant_type: attrs[:participant_type],
      participant_id:   attrs[:participant_id],
      involvable_type:  attrs[:involvable_type],
      involvable_id:    attrs[:involvable_id]
    )
    inv.role = attrs[:role]
    inv.year = attrs[:year]
    inv.note = attrs[:note]

    if inv.save
      render json: involvement_json(inv), status: :created
    else
      render json: { errors: inv.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    inv = Involvement.find_by!(
      participant_type: attrs[:participant_type],
      participant_id:   attrs[:participant_id],
      involvable_type:  attrs[:involvable_type],
      involvable_id:    attrs[:involvable_id]
    )
    inv.update(role: attrs[:role], year: attrs[:year], note: attrs[:note])
    render json: involvement_json(inv), status: :ok
  end

  def destroy
    inv = Involvement.find(params[:id])
    inv.destroy
    head :no_content
  end

  private

  def involvement_params
    params.require(:involvement).permit(
      :involvable_type, :involvable_id,
      :participant_id,
      :role, :year, :note
    )
  end

  def involvement_json(inv)
    {
      id: inv.id,
      participant_id:   inv.participant_id,
      participant_type: inv.participant_type,
      participant_label: inv.participant_label,
      role: inv.role,
      year: inv.year,
      note: inv.note
    }
  end
end
