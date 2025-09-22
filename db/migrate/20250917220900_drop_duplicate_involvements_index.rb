class DropDuplicateInvolvementsIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :involvements, name: :idx_involvements_participant_involvable_unique, if_exists: true
  end
end
