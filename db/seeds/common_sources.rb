# Picks top N by citation count and sets common=true (safe to re-run)
TOP       = ENV.fetch("TOP_COMMON", "20").to_i
MIN_CITES = ENV.fetch("MIN_CITES", "3").to_i

counts = Citation.group(:source_id).count
ids = counts.select { |_, c| c >= MIN_CITES }
            .sort_by { |_, c| -c }
            .first(TOP)
            .map(&:first)

puts "[seeds] setting common=true for #{ids.size} sources (top=#{TOP}, min_cites=#{MIN_CITES})"
Source.where(id: ids).update_all(common: true)
