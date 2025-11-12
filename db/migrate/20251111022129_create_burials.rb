class CreateBurials < ActiveRecord::Migration[7.1]
 def change
    create_table :burials do |t|
      t.references :cemetery, null: false, foreign_key: true
      t.string  :first_name
      t.string  :middle_name
      t.string  :last_name

      # Optional link to a Soldier (or future Person)
      t.string  :participant_type
      t.bigint  :participant_id
      t.index  [:participant_type, :participant_id]

      # Cemetery-specific facts
      t.date    :birth_date
      t.string  :birth_place
      t.date    :death_date
      t.string  :death_place
      t.text    :inscription

      # Location in cemetery
      t.string  :section
      t.string  :plot
      t.string  :marker
      t.string  :link_url
      
      t.text    :note
      t.timestamps
    end
  end 
end
