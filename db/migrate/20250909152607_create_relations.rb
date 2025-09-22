class CreateRelations < ActiveRecord::Migration[7.1]
  def change
    create_table :relations do |t|
      t.string :from_type, null: false
      t.bigint :from_id, null: false
      t.string :to_type, null: false
      t.bigint :to_id, null: false
      t.string :relation_type, null: false, default: "related"
      t.timestamps
    end
    add_index :relations, [:from_type, :from_id]
    add_index :relations, [:to_type, :to_id]
    add_index :relations, [:from_type, :from_id, :to_type, :to_id, :relation_type], unique: true, name: "index_relations_unique"
  end
end
