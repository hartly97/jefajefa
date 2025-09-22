class AddCitationsCountToSources < ActiveRecord::Migration[7.1]
  def change
    add_column :sources, :citations_count, :integer, default: 0, null: false
    add_index :sources, :citations_count
  end
end
