class FixPgToPagesOnSources < ActiveRecord::Migration[7.1]
  def change
    # Drop the bad column
    remove_column :sources, :pg, :decimal if column_exists?(:sources, :pg)

    # Add the correct one
    add_column :sources, :pages, :string unless column_exists?(:sources, :pages)
  end
end

