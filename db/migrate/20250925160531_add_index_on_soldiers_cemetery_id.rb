class AddIndexOnSoldiersCemeteryId < ActiveRecord::Migration[7.1]
  def change
    add_index :soldiers, :cemetery_id unless index_exists?(:soldiers, :cemetery_id)
  end
end
