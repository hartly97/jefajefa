class CreateCitations < ActiveRecord::Migration[7.1]
  def change
    create_table :citations do |t|
      t.references :source, null: false, foreign_key: true
      t.string  :citable_type, null: false
      t.bigint  :citable_id, null: false
      t.string  :pages
      t.text    :quote
      t.text    :note
      t.timestamps
    end
    add_index :citations, [:citable_type, :citable_id]
    add_index :citations, [:source_id, :citable_type, :citable_id], unique: true, name: "index_citations_uniqueness"
  end
end
