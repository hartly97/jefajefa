# scripts/import_welcome_articles.rb
# Usage:
#   bin/rails runner scripts/import_welcome_articles.rb
#   DRY_RUN=1 UPDATE=1 bin/rails runner scripts/import_welcome_articles.rb
require "nokogiri"

WELCOME_VIEWS_PATH = Rails.root.join("app/views/welcome")
DRY_RUN = ENV["DRY_RUN"].to_s == "1"
UPDATE  = ENV["UPDATE"].to_s == "1"

puts " Scanning: #{WELCOME_VIEWS_PATH}"
html_files = Dir.glob(WELCOME_VIEWS_PATH.join("*.html.erb")).reject { |p| File.basename(p).start_with?("_") }

if html_files.empty?
  puts " No .html.erb files found in welcome view folder."
  exit 1
end

# Helpers
normalize = ->(s) { s.to_s.strip.gsub(/\s+/, " ") }
titleize  = ->(s) { normalize.call(s).tr("_", " ").strip.titleize }
paramize  = ->(s) { normalize.call(s).parameterize }

html_files.each do |filepath|
  filename = File.basename(filepath, ".html.erb")       # e.g., "early_colonial_notes"
  title    = titleize.call(filename)                    # "Early Colonial Notes"
  slug     = paramize.call(filename)                    # "early-colonial-notes"

  puts " Importing: #{filename}  Article: #{title}"

  raw_html = File.read(filepath)

  # Grab tag comments BEFORE rendering (comments might get altered in render stacks)
  # Supported:
  #   <!-- tags: a, b, c -->
  #   <!-- source: Some Book -->
  #   <!-- location: Massachusetts -->
  fr = Nokogiri::HTML.fragment(raw_html)
  all_comments = fr.xpath("//comment()").map { |c| c.text.to_s.strip }

  tag_line      = all_comments.find { |t| t =~ /^tags:/i }&.sub(/^tags:/i, "")
  source_line   = all_comments.find { |t| t =~ /^source:/i }&.sub(/^source:/i, "")
  location_line = all_comments.find { |t| t =~ /^location:/i }&.sub(/^location:/i, "")

  tags = (tag_line || "")
           .split(",")
           .map { |t| titleize.call(t) }
           .reject(&:blank?)
  source_name   = titleize.call(source_line)   if source_line.present?
  location_name = titleize.call(location_line) if location_line.present?

  puts "  Tags: #{tags.join(', ')}" if tags.any?
  puts " Source: #{source_name}" if source_name.present?
  puts " Location: #{location_name}" if location_name.present?

  # Render the ERB to final HTML (no layout)
  # This evaluates helpers/partials etc.
  rendered_html =
    ApplicationController.renderer.render(
      template: "welcome/#{filename}",
      formats:  [:html],
      layout:   false
    )

  # Upsert Article
  article = Article.find_or_initialize_by(slug: slug)
  is_new  = article.new_record?

  if is_new || UPDATE
    article.title = title
    article.body  = rendered_html
    # Set date to file mtime if none present; tweak to your needs
    article.date ||= File.mtime(filepath) rescue nil
  end

  if DRY_RUN
    puts "DRY: #{is_new ? 'create' : 'update'} Article(slug=#{slug})"
  else
    article.save!
  end

  # Link categories (topics, source, location)
  # Normalize names and avoid duplicates by case/space.
  linker = ->(name, type) do
    return if name.blank?
    cat = Category.find_or_create_by!(name: name, category_type: type)
    if DRY_RUN
      puts "DRY: link #{article.slug}  [#{type || 'n/a'}] #{name}"
    else
      Categorization.find_or_create_by!(category: cat, categorizable: article)
    end
  end

  tags.each        { |t| linker.call(t, "topic") }
  linker.call(source_name, "source")
  linker.call(location_name, "location")
end

puts " Finished processing #{html_files.size} file(s).#{DRY_RUN ? ' (dry run)' : ''}"
