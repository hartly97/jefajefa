class AddColumnContentToNewsletters < ActiveRecord::Migration[7.1]
  def change
     add_column :newsletters,:content,:string
     add_column :newsletters,:image,:string
     add_column :newsletters,:file_name,:string
  end
end
