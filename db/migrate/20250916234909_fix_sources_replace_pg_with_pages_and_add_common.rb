class FixSourcesReplacePgWithPagesAndAddCommon < ActiveRecord::Migration[7.1]
  def change
    # Drop pg if still present
    remove_column :sources, :pg, :decimal if column_exists?(:sources, :pg)

    # Add string pages if missing
    add_column :sources, :pages, :string unless column_exists?(:sources, :pages)

    # Add boolean common if missing
    add_column :sources, :common, :boolean, default: false, null: false unless column_exists?(:sources, :common)
  end
end
