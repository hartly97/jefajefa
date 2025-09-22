class AddCommonFlagToSources < ActiveRecord::Migration[7.1]
  def change
    add_column :sources, :common, :boolean, default: false, null: false unless column_exists?(:sources, :common)
    add_index  :sources, :common unless index_exists?(:sources, :common)
  end
end
