class BackfillSourcesCitationsCount < ActiveRecord::Migration[7.1]
     disable_ddl_transaction!

  def up
    # Fast SQL backfill
    execute <<~SQL
      UPDATE sources s
      SET citations_count = sub.cnt
      FROM (
        SELECT source_id, COUNT(*) AS cnt
        FROM citations
        GROUP BY source_id
      ) sub
      WHERE s.id = sub.source_id
    SQL
  end

  def down
    # No-op; keep counters
  end
  end

