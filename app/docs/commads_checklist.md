bin/rails categories:report


bundle exec erblint app/views/soldiers

Index Health Check — Quick Guide
Inspect indexes for a table
• Rails console: ActiveRecord::Base.connection.indexes(:citations).map { |i| [i.name, i.columns, i.unique] }
• Look for same columns appearing multiple times under different names.
Preferred pattern when adding indexes
• Always check by columns, not by name (prevents duplicate-name variants).
• Non-unique: add_index :citations, [:citable_type, :citable_id] unless index_exists?(:citations, [:citable_type,
:citable_id])
• Unique: add_index :citations, [:source_id, :citable_type, :citable_id], unique: true unless index_exists?(:citations,
[:source_id, :citable_type, :citable_id], unique: true)
Cleanup migration (drop duplicate names)
• Use index_name_exists? + remove_index :citations, name: "…" for Rails £ 7.1.
• Keep down empty; we don't want duplicate indexes back.
Verify clean state
• Expect only one index per column set (plus optional simple FK index).
Handy one-liners
• ActiveRecord::Base.connection.indexes(:citations).map(&:name)
• Group by columns to spot dupes quickly.