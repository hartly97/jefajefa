class AddColumPageToSources < ActiveRecord::Migration[7.1]
  def change
    change_column :sources, :pg, :string
  end
end
