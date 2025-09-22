class AddAuthorToArticless < ActiveRecord::Migration[7.1]
  def change
    add_column :articles, :description, :string
    add_column :articles, :posteddate, :date
    add_column :articles, :author, :string
  end
end
