class AddIndexToCitations < ActiveRecord::Migration[7.1]
  def change
    add_index :citations,
  [:source_id, :citable_type, :citable_id, :pages, :quote, :note],
  unique: true,
  name: :index_citations_no_exact_dupes
  end
end
