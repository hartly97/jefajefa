module CitationsHelper
  # Returns [[source, [citations...]], ...] with eager loading
  def grouped_citations_by_source(citable)
    return [] unless citable.respond_to?(:citations)
    citable.citations
           .includes(:source)
           .group_by { |c| c.source }
           .sort_by { |src, _| src&.title.to_s.downcase }
           .map { |src, cites| [src, cites] }
  end
end
