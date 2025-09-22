class AllowManyCitationsPerSourceAndCitable < ActiveRecord::Migration[7.1]
  def change
    if index_exists?(:citations,
                     [:source_id, :citable_type, :citable_id, :pages, :quote, :note],
                     name: :index_citations_no_exact_dupes)
      remove_index :citations, name: :index_citations_no_exact_dupes
    end
  end
end
