namespace :sources do
  # Usage:
  #   bin/rails sources:mark_common                # defaults: top=20, min_cites=3
  #   bin/rails sources:mark_common[50,2]          # top 50, min 2 citations
  desc "Mark top N sources by citation count as common (default N=20, min_cites=3)"
  task :mark_common, [:top, :min_cites] => :environment do |_, args|
    top       = (args[:top] || 20).to_i
    min_cites = (args[:min_cites] || 3).to_i

    counts = Citation.group(:source_id).count  # { source_id => count }
    ids = counts.select { |_, c| c >= min_cites }
                .sort_by { |_, c| -c }
                .first(top)
                .map(&:first)

    updated = Source.where(id: ids).update_all(common: true)
    puts "[sources] Marked #{updated} sources as common (top=#{top}, min_cites=#{min_cites})."
  end
end
