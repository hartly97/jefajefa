class AddCategoryIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :categories, "lower(name)", name: "idx_categories_lower_name" unless index_name_exists?(:categories, "idx_categories_lower_name")
    add_index :categories, :parent_id, name: "idx_categories_parent_id" if Category.column_names.include?("parent_id")
  end
end
