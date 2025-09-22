class Awards < ActiveRecord::Migration[7.1]
  def change
    create_table :awards do |t|
      t.string "name"
      t.string "country"
      t.references :soldier, null: false, foreign_key: true
      t.references :medal,   null: false, foreign_key: true
      t.integer :year
      t.text :note
  end
end
end
