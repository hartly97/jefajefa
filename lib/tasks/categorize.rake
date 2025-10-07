# lib/tasks/categorize_categories.rake
require "csv"

namespace :cat do
  # --------------------------------------------------------------------------
  # Import Categories from CSV
  #
  # Expected headers (case-insensitive):
  #   name, category_type, slug, description
  # Only "name" is required. If slug is blank, it will be generated from name.
  #
  # ENV options:
  #   CSV=tmp/categories.csv     # path to CSV
  #   DRY_RUN=1                  # preview only (no writes)
  #   UPDATE=1                   # update existing rows (name/slug/description/type)
  #   STRICT=1                   # raise on invalid rows instead of skipping
  #
  # Matching strategy:
  #   1) slug (if provided)
  #   2) otherwise by [name, category_type]
  #
  # Examples:
  #   bin/rails cat:import_categories CSV=tmp/categories.csv DRY_RUN=1
  #   bin/rails cat:import_categories CSV=tmp/categories.csv UPDATE=1
  # --------------------------------------------------------------------------
  desc "Import Categories from CSV (headers: name[,category_type,slug,description])"
  task import_categories: :environment do
    path   = ENV["CSV"] || "tmp/categories.csv"
    dry    = ENV["DRY_RUN"].to_s == "1"
    update = ENV["UPDATE"].to_s == "1"
    strict = ENV["STRICT"].to_s == "1"

    abort "CSV not found: #{path}" unless File.exist?(path)

    norm = ->(s) { s.to_s.strip.gsub(/\s+/, " ") }

    stats = Hash.new(0)
    created_ids = []

    puts "== cat:import_categories"
    puts "CSV=#{path} DRY_RUN=#{dry} UPDATE=#{update} STRICT=#{strict}"

    CSV.foreach(path, headers: true) do |row|
      stats[:rows] += 1

      name        = norm.call(row["name"] || row["Name"])
      ctype       = norm.call(row["category_type"] || row["type"] || row["Category Type"])
      slug        = norm.call(row["slug"] || row["Slug"])
      description = row["description"].to_s # keep raw (can be long / markdown)

      if name.blank?
        stats[:skip_blank_name] += 1
        msg = "row #{stats[:rows]}: missing name"
        strict ? (raise msg) : (warn "skip: #{msg}")
        next
      end

      slug = name.parameterize if slug.blank?

      # Find existing by slug first, else by [name, type]
      cat = Category.find_by(slug: slug) ||
            Category.find_by(name: name, category_type: ctype.presence)

      if cat.nil?
        if dry
          puts "DRY: create Category(name=#{name.inspect}, type=#{ctype.inspect}, slug=#{slug.inspect})"
          stats[:would_create] += 1
        else
          cat = Category.new(name: name, category_type: ctype.presence, slug: slug)
          cat.description = description if cat.respond_to?(:description) && description.present?
          if cat.save
            stats[:created] += 1
            created_ids << cat.id
            puts "Created: [#{cat.id}] #{cat.name} (#{cat.category_type || 'n/a'})"
          else
            stats[:invalid] += 1
            msg = "invalid: #{cat.errors.full_messages.join(', ')}"
            strict ? (raise msg) : (warn msg)
          end
        end
      else
        stats[:matched_existing] += 1
        if update
          changed = []
          if cat.name != name
            changed << "name: #{cat.name.inspect}→#{name.inspect}"
            cat.name = name
          end
          if cat.category_type.to_s != ctype.to_s
            changed << "type: #{cat.category_type.inspect}→#{ctype.inspect}"
            cat.category_type = ctype.presence
          end
          if cat.slug != slug
            changed << "slug: #{cat.slug.inspect}→#{slug.inspect}"
            cat.slug = slug
          end
          if cat.respond_to?(:description) && description.present? && cat.description.to_s != description.to_s
            changed << "description: <changed>"
            cat.description = description
          end

          if changed.any?
            if dry
              puts "DRY: update [#{cat.id}] #{changed.join(', ')}"
              stats[:would_update] += 1
            else
              if cat.save
                stats[:updated] += 1
                puts "Updated: [#{cat.id}] #{changed.join(', ')}"
              else
                stats[:invalid] += 1
                msg = "invalid update [#{cat.id}]: #{cat.errors.full_messages.join(', ')}"
                strict ? (raise msg) : (warn msg)
              end
            end
          else
            stats[:no_change] += 1
          end
        else
          stats[:skipped_existing] += 1
        end
      end
    end

    puts "\n== Summary =="
    stats.each { |k,v| puts "%-20s %d" % ["#{k}:", v] }
    puts "New IDs: #{created_ids.join(', ')}" if created_ids.any?
    puts "Done."
  end

  # Simple exporter (handy to generate a starter CSV you can edit)
  desc "Export Categories to CSV (name,category_type,slug,description)"
  task export_categories: :environment do
    path = ENV["CSV"] || "tmp/categories_export.csv"
    CSV.open(path, "w") do |csv|
      csv << %w[name category_type slug description]
      Category.order(:category_type, :name).find_each do |c|
        csv << [c.name, c.category_type, c.slug, (c.respond_to?(:description) ? c.description : nil)]
      end
    end
    puts "Wrote #{path}"
  end
end
