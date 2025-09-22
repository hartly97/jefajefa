# test/system/articles_slug_test.rb
require "application_system_test_case"

class ArticlesSlugTest < ApplicationSystemTestCase
  test "regenerating a slug updates the article" do
    article = Article.create!(title: "Unique Slug Test")

    visit article_path(article)
    old_slug = article.slug

    assert_text "Current slug:"
    assert_text old_slug

    click_button "Regenerate slug"

    article.reload
    new_slug = article.slug

    assert_not_equal old_slug, new_slug, "Slug should have changed"
    assert_text new_slug
  end
end
