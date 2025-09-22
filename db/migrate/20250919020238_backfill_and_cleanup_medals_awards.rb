class BackfillAndCleanupMedalsAwards < ActiveRecord::Migration[7.1]
  def up
    say_with_time "Backfilling soldier_medals from awards.medal_id (no duplicates)" do
      execute <<~SQL.squish
        INSERT INTO soldier_medals (soldier_id, medal_id, year, note, created_at, updated_at)
        SELECT a.soldier_id, a.medal_id, a.year, a.note, NOW(), NOW()
        FROM awards a
        WHERE a.medal_id IS NOT NULL
          AND NOT EXISTS (
            SELECT 1 FROM soldier_medals sm
            WHERE sm.soldier_id = a.soldier_id
              AND sm.medal_id   = a.medal_id
              AND COALESCE(sm.year, -1) = COALESCE(a.year, -1)
          )
      SQL
    end

    # Drop any check constraint that enforced medal OR name on awards
    # Try a common name first, then fall back to a dynamic drop by searching pg_constraint.
    begin
      execute "ALTER TABLE awards DROP CONSTRAINT IF EXISTS awards_medal_or_name_ck"
    rescue
    end

    # Attempt to find and drop any unnamed check constraints that match the old logic
    say_with_time "Dropping legacy awards check constraint if present" do
      execute <<~SQL
        DO $$
        DECLARE
          cname text;
        BEGIN
          SELECT conname INTO cname
          FROM pg_constraint
          WHERE conrelid = 'awards'::regclass
            AND contype = 'c'
            AND pg_get_constraintdef(oid) ILIKE '%medal_id IS NOT NULL%OR%name IS NOT NULL%';
          IF cname IS NOT NULL THEN
            EXECUTE format('ALTER TABLE awards DROP CONSTRAINT %I', cname);
          END IF;
        END$$;
      SQL
    end

    # Drop FK/index and the column awards.medal_id
    if foreign_key_exists?(:awards, :medals)
      remove_foreign_key :awards, :medals
    end
    if index_exists?(:awards, :medal_id)
      remove_index :awards, :medal_id
    end
    if column_exists?(:awards, :medal_id)
      remove_column :awards, :medal_id
    end
  end

  def down
    # Recreate the column + FK (no data backfill to awards)
    unless column_exists?(:awards, :medal_id)
      add_reference :awards, :medal, foreign_key: true, index: true
    end

    # (Optional) Recreate the old check constraint requiring medal OR name
    # Uncomment if you want it back:
    # execute <<~SQL
    #   ALTER TABLE awards
    #   ADD CONSTRAINT awards_medal_or_name_ck
    #   CHECK (medal_id IS NOT NULL OR (name IS NOT NULL AND btrim(name) <> ''));
    # SQL
  end
end

 
