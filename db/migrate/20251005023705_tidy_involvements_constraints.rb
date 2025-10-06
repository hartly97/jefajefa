class TidyInvolvementsConstraints < ActiveRecord::Migration[7.1]
  def up
    # 1) Remove any Article involvements
    execute "DELETE FROM involvements WHERE involvable_type = 'Article';"

    # 2) Ensure there is only ONE unique index on the 4-key tuple
    if index_exists?(:involvements,
                     [:participant_type, :participant_id, :involvable_type, :involvable_id],
                     name: "index_involvements_unique_link")
      remove_index :involvements, name: "index_involvements_unique_link"
    end

    unless index_exists?(:involvements,
                         [:participant_type, :participant_id, :involvable_type, :involvable_id],
                         name: "idx_involvements_unique_link")
      add_index :involvements,
                [:participant_type, :participant_id, :involvable_type, :involvable_id],
                unique: true,
                name: "idx_involvements_unique_link"
    end

    # 3) Drop any duplicate constraints with the "involvements_*" names
    execute "ALTER TABLE involvements DROP CONSTRAINT IF EXISTS chk_involvements_involvable_type;"
    execute "ALTER TABLE involvements DROP CONSTRAINT IF EXISTS chk_involvements_participant_type;"
    execute "ALTER TABLE involvements DROP CONSTRAINT IF EXISTS chk_involvements_year_range;"

    # 4) Recreate single canonical checks (no Article allowed)
    execute "ALTER TABLE involvements DROP CONSTRAINT IF EXISTS chk_inv_involvable_type;"
    execute "ALTER TABLE involvements ADD  CONSTRAINT chk_inv_involvable_type CHECK (involvable_type IN ('War','Battle','Cemetery'));"

    execute "ALTER TABLE involvements DROP CONSTRAINT IF EXISTS chk_inv_participant_type;"
    execute "ALTER TABLE involvements ADD  CONSTRAINT chk_inv_participant_type CHECK (participant_type = 'Soldier');"

    execute "ALTER TABLE involvements DROP CONSTRAINT IF EXISTS chk_inv_year_range;"
    execute "ALTER TABLE involvements ADD  CONSTRAINT chk_inv_year_range CHECK (year IS NULL OR (year > 0 AND year < 3000));"
  end

  def down
    # Loosen involvable type to allow Article again (single canonical name)
    execute "ALTER TABLE involvements DROP CONSTRAINT IF EXISTS chk_inv_involvable_type;"
    execute "ALTER TABLE involvements ADD  CONSTRAINT chk_inv_involvable_type CHECK (involvable_type IN ('War','Battle','Cemetery','Article'));"

    # We intentionally do not recreate any duplicate unique index that may have existed before.
  end
end

