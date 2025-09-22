namespace :medals do
  desc "Report medals recorded both in awards.medal_id and soldier_medals (potential duplicates)"
  task audit: :environment do
    puts "Scanning for overlapping medal entries…"
    sql = <<~SQL
      SELECT a.soldier_id, a.medal_id, a.year,
             COUNT(sm.*) AS soldier_medals_count
      FROM awards a
      JOIN soldier_medals sm
        ON sm.soldier_id = a.soldier_id
       AND sm.medal_id   = a.medal_id
       AND COALESCE(sm.year, -1) = COALESCE(a.year, -1)
      WHERE a.medal_id IS NOT NULL
      GROUP BY a.soldier_id, a.medal_id, a.year
    SQL

    rows = ActiveRecord::Base.connection.exec_query(sql)
    if rows.rows.empty?
      puts "✅ No overlaps detected."
    else
      puts "⚠️ Overlaps found (these exist in BOTH awards and soldier_medals):"
      rows.each { |r| puts "  soldier_id=#{r['soldier_id']} medal_id=#{r['medal_id']} year=#{r['year'] || 'NULL'}" }
      puts "\nTip: clear award.medal_id (make it a non-medal award) once you confirm soldier_medals has the record."
    end
  end
end
