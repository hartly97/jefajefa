class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :category_type
      t.text   :description
      t.string :slug, null: false
      t.timestamps
    end
    add_index :categories, [:category_type, :name]
    add_index :categories, :slug, unique: true
  end
end


