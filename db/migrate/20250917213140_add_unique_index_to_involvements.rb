class AddUniqueIndexToInvolvements < ActiveRecord::Migration[7.1]
  def change
     add_index :involvements,
      [:participant_type, :participant_id, :involvable_type, :involvable_id],
      unique: true,
      name: "idx_involvements_participant_involvable_unique"
  end
end
