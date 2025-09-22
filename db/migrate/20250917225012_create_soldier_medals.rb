class CreateSoldierMedals < ActiveRecord::Migration[7.1]
  def up
    return if table_exists?(:soldier_medals)

    create_table :soldier_medals do |t|
      t.references :soldier, null: false, foreign_key: true
      t.references :medal,   null: false, foreign_key: true
      t.integer :year
      t.text    :note
      t.timestamps
    end

    add_index :soldier_medals, [:soldier_id, :medal_id, :year],
              name: "idx_soldier_medals_uniqueish", if_not_exists: true
  end

  def down
    drop_table :soldier_medals if table_exists?(:soldier_medals)
  end
end
