class BackfillAndDropMedalIdFromAwards < ActiveRecord::Migration[7.1]
  def change
    def up
    if column_exists?(:awards, :medal_id)
      execute <<~SQL.squish
        INSERT INTO soldier_medals (soldier_id, medal_id, year, note, created_at, updated_at)
        SELECT awards.soldier_id, awards.medal_id, awards.year, awards.note, NOW(), NOW()
        FROM awards
        WHERE awards.medal_id IS NOT NULL
      SQL
      remove_column :awards, :medal_id
    end
  end

  def down
    # Re-create the column, but we cannot faithfully reverse the backfill without extra bookkeeping.
    add_column :awards, :medal_id, :bigint unless column_exists?(:awards, :medal_id)
    add_foreign_key :awards, :medals, column: :medal_id
  end
end
end
