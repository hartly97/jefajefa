class HardenInvolvements < ActiveRecord::Migration[7.1]
  def up
    add_index :involvements,
      [:participant_type, :participant_id, :involvable_type, :involvable_id],
      unique: true,
      name: "idx_involvements_unique_link",
      if_not_exists: true

    execute "ALTER TABLE involvements DROP CONSTRAINT IF EXISTS chk_involvements_participant_type"
    execute "ALTER TABLE involvements ADD CONSTRAINT chk_involvements_participant_type CHECK (participant_type IN ('Soldier'))"

    execute "ALTER TABLE involvements DROP CONSTRAINT IF EXISTS chk_involvements_involvable_type"
    execute "ALTER TABLE involvements ADD CONSTRAINT chk_involvements_involvable_type CHECK (involvable_type IN ('Battle','War','Cemetery','Article'))"

    execute "ALTER TABLE involvements DROP CONSTRAINT IF EXISTS chk_involvements_year_range"
    execute "ALTER TABLE involvements ADD CONSTRAINT chk_involvements_year_range CHECK (year IS NULL OR (year > 0 AND year < 3000))"
  end

  def down
    remove_index :involvements, name: "idx_involvements_unique_link", if_exists: true
    execute "ALTER TABLE involvements DROP CONSTRAINT IF EXISTS chk_involvements_participant_type"
    execute "ALTER TABLE involvements DROP CONSTRAINT IF EXISTS chk_involvements_involvable_type"
    execute "ALTER TABLE involvements DROP CONSTRAINT IF EXISTS chk_involvements_year_range"
  end
end
