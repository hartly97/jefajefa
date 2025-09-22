class BackfillCitationsPageFromPages < ActiveRecord::Migration[7.1]
  def change
    def up
    say_with_time "Copying citations.pages into citations.page where page is blank" do
      # prefer page if it already has value; otherwise copy pages over
      execute <<~SQL.squish
        UPDATE citations
        SET page = pages
        WHERE (page IS NULL OR btrim(page) = '')
          AND pages IS NOT NULL AND btrim(pages) <> ''
      SQL
    end
  end

  def down
    # no destructive change; do nothing
  end
  end
end
