# app/helpers/articles_helper.rb
module ArticlesHelper
  def grouped_citations_by_source(article)
    groups = article.citations.includes(:source).group_by(&:source)

    # sort citations inside each group
    groups.each_value do |arr|
      arr.sort_by! { |c| [(c.pages || c.page).to_s, c.id] }
    end

    # return an Array of [source, citations] sorted by source title (nil last)
    groups.sort_by { |src, _| [src.nil? ? 1 : 0, src&.title.to_s.downcase] }
  end
end
