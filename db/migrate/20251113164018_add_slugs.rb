class AddSlugs < ActiveRecord::Migration[7.1]
  TABLES = %i[
  burials
    awards
    medals
    soldier_medals
    cemeteries
    categories
    censuses
    census_entries
    newsletters
  ]

  def change
    TABLES.each do |t|
      add_column t, :slug, :string unless column_exists?(t, :slug)
      add_index  t, "LOWER(slug)", unique: true, name: "idx_#{t}_lower_slug" unless index_exists?(t, "LOWER(slug)", name: "idx_#{t}_lower_slug")
    end
  end
end

