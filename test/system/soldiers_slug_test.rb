# test/system/soldiers_slug_test.rb
require "application_system_test_case"

class SoldiersSlugTest < ApplicationSystemTestCase
  test "regenerating a slug updates the Soldier" do
    soldier = Soldier.create!(title: "Unique Slug Test")

    visit soldier_path(soldier)
    old_slug = soldier.slug

    assert_text "Current slug:"
    assert_text old_slug

    click_button "Regenerate slug"

    soldier.reload
    new_slug = soldier.slug

    assert_not_equal old_slug, new_slug, "Slug should have changed"
    assert_text new_slug
  end
end
