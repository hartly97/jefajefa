class CreateNewsletters < ActiveRecord::Migration[7.1]
  def change
    create_table :newsletters do |t|
      t.string :volume, null: false
      t.string :number, null: false
      t.string :day, null: false
      t.string :month, null: false
      t.string :year, null: false
      t.string :title, null: false
    t.string :slug,  null: false
    end
  end
end
