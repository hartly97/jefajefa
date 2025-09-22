# lib/tasks/split_csv_by_type.rb
require "csv"

# Usage:
#   bin/rails runner lib/tasks/split_csv_by_type.rb tmp/csv/mixed.csv tmp/csv/outdir
#
# Example input CSV (with a `type` column):
#   slug,category,type
#   soldier-1,War of 1812,war
#   soldier-2,Battle of Tippecanoe,battle
#   article-1,Colonial History,topic
#
# Output:
#   tmp/csv/outdir/war.csv
#   tmp/csv/outdir/battle.csv
#   tmp/csv/outdir/topic.csv

input  = ARGV[0] || abort("Usage: rails runner split_csv_by_type.rb input.csv outdir")
outdir = ARGV[1] || abort("Usage: rails runner split_csv_by_type.rb input.csv outdir")

Dir.mkdir(outdir) unless Dir.exist?(outdir)

groups = Hash.new { |h, k| h[k] = [] }

CSV.foreach(input, headers: true) do |row|
  type = row["type"].to_s.strip.downcase
  next if type.empty?
  groups[type] << row
end

groups.each do |type, rows|
  out_path = File.join(outdir, "#{type}.csv")
  CSV.open(out_path, "w") do |csv|
    csv << rows.first.headers  # keep same headers
    rows.each { |r| csv << r }
  end
  puts "Wrote #{rows.size} rows -> #{out_path}"
end
