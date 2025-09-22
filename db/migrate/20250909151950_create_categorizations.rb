class CreateCategorizations < ActiveRecord::Migration[7.1]
  def change
    create_table :categorizations do |t|
      t.references :category, null: false, foreign_key: true
      t.string  :categorizable_type, null: false
      t.bigint  :categorizable_id, null: false
      t.integer :position
      t.timestamps
    end
    add_index :categorizations, [:categorizable_type, :categorizable_id], name: "index_categorizations_on_categorizable"
    add_index :categorizations, [:category_id, :categorizable_type, :categorizable_id], unique: true, name: "index_categorizations_on_all"
  end
end

