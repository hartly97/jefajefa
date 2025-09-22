class CreateInvolvements < ActiveRecord::Migration[7.1]
  def change
    create_table :involvements do |t|
      t.string :participant_type, null: false
      t.bigint :participant_id, null: false
      t.string :involvable_type, null: false
      t.bigint :involvable_id, null: false
      t.string :role
      t.integer :year
      t.text :note
      t.timestamps
    end
    add_index :involvements, [:participant_type, :participant_id]
    add_index :involvements, [:involvable_type, :involvable_id]
    add_index :involvements, [:participant_type, :participant_id, :involvable_type, :involvable_id], unique: true, name: "index_involvements_unique_link"
  end
end

