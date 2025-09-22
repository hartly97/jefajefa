namespace :census do
  # Usage:
  #   SIM=0.30 LOC=0.20 DRY=1  bin/rails census:link_soldiers
  # ENV:
  #   SIM  -> name similarity threshold (0..1), default 0.35
  #   LOC  -> location score threshold (0..1), default 0.15
  #   DRY  -> "1" for dry-run (no writes)
  task link_soldiers: :environment do
    sim_threshold = (ENV["SIM"] || 0.35).to_f
    loc_threshold = (ENV["LOC"] || 0.15).to_f
    dry_run       = ENV["DRY"] == "1"

    puts "[link] SIM=#{sim_threshold} LOC=#{loc_threshold} DRY=#{dry_run ? 'YES' : 'NO'}"

    # Ensure pg_trgm index for names exists (fast similarity)
    ActiveRecord::Base.connection.execute(<<~SQL)
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_indexes WHERE indexname = 'idx_soldiers_name_trgm'
        ) THEN
          CREATE INDEX idx_soldiers_name_trgm
          ON soldiers
          USING gin ((lower(first_name || ' ' || last_name)) gin_trgm_ops);
        END IF;
      END$$;
    SQL

    # Optional basic btree indexes to help filter by birthplace/country
    ActiveRecord::Base.connection.execute(<<~SQL)
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_soldiers_birthcity') THEN
          CREATE INDEX idx_soldiers_birthcity ON soldiers (lower(coalesce(birthcity,'')));
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_soldiers_birthcountry') THEN
          CREATE INDEX idx_soldiers_birthcountry ON soldiers (lower(coalesce(birthcountry,'')));
        END IF;
      END$$;
    SQL

    # Normalize helpers
    norm = ->(s) { s.to_s.downcase.strip }
    toks = ->(s) { norm.call(s).gsub(/[^a-z0-9\s]/, " ").split(/\s+/).reject(&:blank?) }

    matched = 0
    considered = 0
    updated = 0
    skipped_existing = 0
    no_name = 0
    no_candidates = 0

    CensusEntry.find_each do |e|
      if e.soldier_id.present?
        skipped_existing += 1
        next
      end

      name = [e.firstname, e.lastname].compact.join(" ").strip
      if name.blank?
        no_name += 1
        next
      end

      considered += 1
      birth_city_e     = norm.call(e.birthlikeplacetext.presence || e.location)
      birth_country_e  = norm.call(e.birthcountry)
      tokens_city_e    = toks.call(birth_city_e)

      # Candidate soldiers by trigram name similarity, top 10
      sql = <<~SQL
        SELECT id,
               similarity(lower(first_name || ' ' || last_name), $1) AS sim,
               lower(coalesce(birthcity,''))   AS city,
               lower(coalesce(birthcountry,'')) AS country
        FROM soldiers
        WHERE lower(first_name || ' ' || last_name) % $1
        ORDER BY sim DESC
        LIMIT 10
      SQL
      candidates = ActiveRecord::Base.connection.exec_query(sql, "SQL", [[nil, name.downcase]]).to_a

      if candidates.empty?
        no_candidates += 1
        next
      end

      # Score each candidate on (a) name similarity and (b) birthplace/country proximity.
      best = candidates
        .select { |row| row["sim"].to_f >= sim_threshold }
        .map do |row|
          city_s    = row["city"].to_s
          country_s = row["country"].to_s

          # simple token overlap for city (handles "Devon, Throwleigh" vs "Throwleigh")
          city_tokens_s = toks.call(city_s)
          city_overlap  = (tokens_city_e & city_tokens_s).size
          city_union    = (tokens_city_e | city_tokens_s).size
          city_jaccard  = city_union.zero? ? 0.0 : city_overlap.to_f / city_union

          # country match: exact (1.0), empty on either side (0.0), else 0.25 if one contains the other token
          country_score =
            if birth_country_e.blank? || country_s.blank?
              0.0
            elsif birth_country_e == country_s
              1.0
            elsif birth_country_e.include?(country_s) || country_s.include?(birth_country_e)
              0.25
            else
              0.0
            end

          # Combine: 60% name, 40% location (with city 75% of that, country 25%)
          loc_score = (0.75 * city_jaccard) + (0.25 * country_score)
          combined  = (0.60 * row["sim"].to_f) + (0.40 * loc_score)

          row.merge("city_jaccard" => city_jaccard, "country_score" => country_score, "loc_score" => loc_score, "combined" => combined)
        end
        .sort_by { |r| -r["combined"] }
        .first

      if best && best["loc_score"].to_f >= loc_threshold
        matched += 1
        if dry_run
          puts "[dry] would link entry##{e.id} '#{name}' -> soldier##{best["id"]} "\
               "(sim=#{'%.2f' % best["sim"]}, loc=#{'%.2f' % best["loc_score"]}, score=#{'%.2f' % best["combined"]})"
        else
          e.update_column(:soldier_id, best["id"])
          updated += 1
          puts "[link] entry##{e.id} '#{name}' -> soldier##{best["id"]} "\
               "(sim=#{'%.2f' % best["sim"]}, loc=#{'%.2f' % best["loc_score"]}, score=#{'%.2f' % best["combined"]})"
        end
      else
        no_candidates += 1
      end
    end

    puts "[summary] considered=#{considered} updated=#{updated} matched=#{matched} "\
         "skipped_existing=#{skipped_existing} no_name=#{no_name} no_candidates=#{no_candidates}"
  end
end
