# lib/tasks/csv_import.rake
#legacy categories


  desc "Import soldiers from CSV"
  task soldiers: :environment do
    load "scripts/import_soldiers_from_csv.rb"
  end
end

namespace :logs do
  desc "Show the most recent dry-run log file"
  task :latest_dry_run do
    log_dir = Rails.root.join("tmp/log")
    files = Dir.glob("\#{log_dir}/dry_run_*.log").sort_by { |f| File.mtime(f) }.reverse

    if files.empty?
      puts " No dry-run log files found."
    else
      latest = files.first
      puts " Showing latest dry-run log: \#{latest}"
      puts "-" * 60
      puts File.read(latest)
    end
  end
end


namespace :logs do
  desc "Delete all dry-run log files"
  task :clean_dry_run do
    log_dir = Rails.root.join("tmp/log")
    files = Dir.glob("\#{log_dir}/dry_run_*.log")
    if files.empty?
      puts " No dry-run logs to delete."
    else
      files.each { |f| File.delete(f) }
      puts " Deleted \#{files.size} dry-run log(s)."
    end
  end

  desc "Archive all dry-run logs to shared/exports"
  task :archive_dry_run do
    log_dir = Rails.root.join("tmp/log")
    export_dir = Rails.root.join("shared/exports")
    Dir.mkdir(export_dir) unless Dir.exist?(export_dir)

    files = Dir.glob("\#{log_dir}/dry_run_*.log")
    if files.empty?
      puts " No dry-run logs to archive."
    else
      files.each do |file|
        filename = File.basename(file)
        FileUtils.mv(file, File.join(export_dir, filename))
      end
      puts " Moved \#{files.size} log(s) to shared/exports."
    end
  end
end
