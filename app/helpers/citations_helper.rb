# app/helpers/citations_helper.rb
module CitationsHelper
  # Groups an object's citations by Source, sorted by source title.
  # Returns an array of [source, citations] pairs.
  # Enforces your rule: no orphan citations (source must be present).
  def grouped_citations_by_source(citable)
    return [] unless citable.respond_to?(:citations)

    citable.citations
           .includes(:source)
           .select { |c| c.source.present? }                 # enforce "no orphan citations"
           .group_by(&:source)
           .sort_by { |src, _| src.title.to_s.downcase }     # sort sources A–Z
           .map { |src, cites| [src, cites] }
  end

  # Merges citations for a single source by page label.
  # Returns an array of [label, [citations]] pairs, sorted by page label.
  #
  # Example output:
  #   [["3", [#<Citation ...>]], ["12–15", [#<Citation ...>, #<Citation ...>]], ["(Unpaged)", [...]]]
  def merge_citations_by_page(cites)
    groups = cites.group_by { |c| page_label_for(c) }
    groups
      .sort_by { |label, _| page_sort_key(label) }
      .map { |label, arr| [label, arr] }
  end

  # ---- helpers used above ----

  # Prefer `pages`, fall back to `page`, else a friendly placeholder.
  def page_label_for(citation)
    (citation.pages.presence || citation.page.presence || "(Unpaged)").to_s.strip
  end

  # Sort keys: first number in the label (if any), then the full label for stability.
  # Unnumbered labels sort to the end.
  def page_sort_key(label)
    if (m = label.match(/(\d+)/))
      [m[1].to_i, label]
    else
      [Float::INFINITY, label]
    end
  end
end
