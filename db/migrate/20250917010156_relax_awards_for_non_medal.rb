class RelaxAwardsForNonMedal < ActiveRecord::Migration[7.1]
  def up
    # allow awards without a medal
    change_column_null :awards, :medal_id, true

    # CHECK: must have medal_id OR name
    execute <<~SQL
      ALTER TABLE awards
      ADD CONSTRAINT awards_medal_or_name_ck
      CHECK (medal_id IS NOT NULL OR (name IS NOT NULL AND btrim(name) <> ''));
    SQL

    # Unique constraints to prevent obvious dupes (partial indexes)
    execute <<~SQL
      CREATE UNIQUE INDEX index_awards_on_soldier_medal_year
      ON awards (soldier_id, medal_id, year)
      WHERE medal_id IS NOT NULL;
    SQL

    execute <<~SQL
      CREATE UNIQUE INDEX index_awards_on_soldier_name_year
      ON awards (soldier_id, lower(name), year)
      WHERE name IS NOT NULL AND btrim(name) <> '';
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_awards_on_soldier_name_year;"
    execute "DROP INDEX IF EXISTS index_awards_on_soldier_medal_year;"
    execute "ALTER TABLE awards DROP CONSTRAINT IF EXISTS awards_medal_or_name_ck;"
    change_column_null :awards, :medal_id, false
  end
end
  
