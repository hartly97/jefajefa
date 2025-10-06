class AddIndexToCategories < ActiveRecord::Migration[7.1]
  def change
    add_index :categories, [:name, :category_type], unique: true
  end
end
