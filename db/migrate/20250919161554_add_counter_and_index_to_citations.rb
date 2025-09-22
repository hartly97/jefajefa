class AddCounterAndIndexToCitations < ActiveRecord::Migration[7.1]
  def change
     def change
    # counter cache on sources
    add_column :sources, :citations_count, :integer, default: 0, null: false

    # unique composite index to enforce one citation per (citable, source)
    add_index :citations,
              [:citable_type, :citable_id, :source_id],
              unique: true,
              name: "idx_citations_unique_citable_source"
     end
  end
end
