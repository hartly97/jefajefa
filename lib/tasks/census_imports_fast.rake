# lib/tasks/census_import.rake
require "csv"

namespace :census do
  desc "Fast load CSVs into census_imports with COPY (Postgres only)"
  task copy_load: :environment do
    path = ENV["CSV"]
    abort "Usage: CSV=/path/to/file.csv bin/rails census:copy_load" unless path && File.exist?(path)

    conn = ActiveRecord::Base.connection.raw_connection
    table = "census_imports"
    cols  = ActiveRecord::Base.connection.columns(table).map(&:name)
    puts "[census] COPY into #{table} (#{cols.size} columns)"

    conn.exec("COPY #{table} (#{cols.join(",")}) FROM STDIN WITH (FORMAT csv, HEADER true, NULL '', QUOTE '\"')")
    File.open(path, "r") do |f|
      while (chunk = f.read(1 << 20)) # 1MB chunks
        conn.put_copy_data(chunk)
      end
    end
    conn.put_copy_end
    while res = conn.get_result
      raise res.error_message unless res.result_status == PG::PGRES_COMMAND_OK
    end
    puts "[census] COPY done."
  end
end