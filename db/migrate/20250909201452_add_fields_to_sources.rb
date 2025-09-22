class AddFieldsToSources < ActiveRecord::Migration[7.1]
  def change
    add_column :sources, :author, :string
    add_column :sources, :publisher, :string
    add_column :sources, :year, :string
    add_column :sources, :url, :string
  end
end
