class IndexCategorizationsOnPolyAndCategory < ActiveRecord::Migration[7.1]
  def change
  add_index :categorizations,
  [:categorizable_type, :categorizable_id, :category_id],
  unique: true,
  name: "index_categorizations_on_poly_and_category"

  end
end
