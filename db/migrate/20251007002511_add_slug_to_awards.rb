class AddSlugToAwards < ActiveRecord::Migration[7.1]
    def change
    add_column :awards, :slug, :string
    add_index  :awards, :slug, unique: true
  end
  end

