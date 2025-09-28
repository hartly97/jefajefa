# app/helpers/articles_helper.rb
module ArticlesHelper
  def grouped_citations_by_source(article)
    article.citations
           .includes(:source)
           .sort_by { |c| [c.source&.title.to_s.downcase, (c.pages || c.page).to_s, c.id] }
           .group_by { |c| c.source&.title.presence || "(no source)" }
  end
end
