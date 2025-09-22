class RelaxCitationsUniquePair < ActiveRecord::Migration[7.1]
  def change
    # Remove the strict unique index
    remove_index :citations, name: :index_citations_uniqueness

    # Optional: add a non-unique covering index for speed
    add_index :citations, [:source_id, :citable_type, :citable_id], name: :index_citations_pair
  end
end
