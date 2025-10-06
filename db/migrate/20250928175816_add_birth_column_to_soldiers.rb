class AddBirthColumnToSoldiers < ActiveRecord::Migration[7.1]
  def change
    add_column :soldiers, :birth_date, :string
     add_column :soldiers, :death_date, :string
      add_column :soldiers, :deathplace, :string
       add_column :soldiers, :birthplace, :string
      
        add_column :soldiers, :first_enlisted_start_date, :string
        add_column :soldiers, :first_enlisted_end_date, :string
        add_column :soldiers, :first_enlisted_place, :string
        add_column :soldiers, :branch_of_service, :string
        add_column :soldiers, :unit, :string
        
  end
end
