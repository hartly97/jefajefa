class AddSlugToNewsletters < ActiveRecord::Migration[7.1]
  def change
     add_index  :newsletters, :slug, unique: true
  end
end
