# lib/tasks/census_link.rake
namespace :census do
  desc "Link census_entries to soldiers using pg_trgm fuzzy matching"
  task link_soldiers: :environment do
    threshold = (ENV["SIM"] || 0.35).to_f  # 0..1, higher = stricter

    # Precompute soldier name strings
    soldiers = Soldier.select(:id, :first_name, :last_name, :birthcity, :birthcountry).map do |s|
      {
        id: s.id,
        name: [s.first_name, s.last_name].compact.join(" ").downcase,
        birthcity: s.birthcity&.downcase,
        birthcountry: s.birthcountry&.downcase
      }
    end

    # Add a trigram index to speed up similarity (one-time)
    ActiveRecord::Base.connection.execute(<<~SQL)
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_indexes WHERE indexname = 'idx_soldiers_name_trgm'
        ) THEN
          CREATE INDEX idx_soldiers_name_trgm ON soldiers USING gin ((lower(first_name || ' ' || last_name)) gin_trgm_ops);
        END IF;
      END$$;
    SQL

    matched, total = 0, 0

    CensusEntry.where(soldier_id: nil).find_each do |e|
      total += 1
      name = [e.firstname, e.lastname].compact.join(" ").downcase
      next if name.blank?

      # Quick SQL similarity (fast):
      sql = <<~SQL
        SELECT id, (similarity(lower(first_name || ' ' || last_name), $1)) AS sim
        FROM soldiers
        WHERE lower(first_name || ' ' || last_name) % $1  -- uses pg_trgm
        ORDER BY sim DESC
        LIMIT 5
      SQL
      candidates = ActiveRecord::Base.connection.exec_query(sql, "SQL", [[nil, name]]).to_a

      cand = candidates.find { |row| row["sim"].to_f >= threshold }
      if cand
        e.update_column(:soldier_id, cand["id"])
        matched += 1
      end
    end

    puts "[link] matched #{matched} / #{total} entries (threshold #{threshold})"
  end
end
