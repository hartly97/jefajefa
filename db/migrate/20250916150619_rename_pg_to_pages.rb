class RenamePgToPages < ActiveRecord::Migration[7.1]
 def up
    if column_exists?(:sources, :pg)
      rename_column :sources, :pg, :pages
    elsif !column_exists?(:sources, :pages)
      add_column :sources, :pages, :string
    end

    # ensure it's a string for ranges like "1215"
    if column_exists?(:sources, :pages) &&
       ActiveRecord::Base.connection.columns(:sources).find { |c| c.name == "pages" }&.sql_type != "character varying"
      change_column :sources, :pages, :string
    end
  end

  def down
    # Only revert if we truly renamed
    if column_exists?(:sources, :pages) && !column_exists?(:sources, :pg)
      # If you want to support full rollback, you can rename back:
      # rename_column :sources, :pages, :pg
      # (but most folks leave it as no-op)
    end
  end
end
