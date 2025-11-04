class AddSlugToCensusEntries < ActiveRecord::Migration[7.1]
  def change
    add_column :census_entries, :slug, :string
    add_index  :census_entries, :slug, unique: true, where: "slug IS NOT NULL"
  end
end
