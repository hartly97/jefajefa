class AddColumnVersionToNewsletters < ActiveRecord::Migration[7.1]
  def change
   add_column :newsletters,:version,:string
  end
end
