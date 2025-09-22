class CreateOrPatchSoldierMedals < ActiveRecord::Migration[7.1]
  def change
    create_table :or_patch_soldier_medals do |t|
      create_table :soldier_medals, if_not_exists: true do |t|
      t.references :soldier, null: false, foreign_key: true
      t.references :medal,   null: false, foreign_key: true
      t.integer :year
      t.text    :note
      t.timestamps
    end
    add_index :soldier_medals, [:soldier_id, :medal_id, :year],
              name: "idx_soldier_medals_uniqueish", if_not_exists: true
      t.timestamps
    end
  end
end
