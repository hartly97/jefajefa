class  AddLocatorFieldsToCitations < ActiveRecord::Migration[7.1]
  def change
    change_table :citations, bulk: true do |t|
      t.string  :volume      unless column_exists?(:citations, :volume)
      t.string  :issue       unless column_exists?(:citations, :issue)
      t.string  :folio       unless column_exists?(:citations, :folio)
      t.string  :page        unless column_exists?(:citations, :page)        # page or range ("12–15")
      t.string  :column      unless column_exists?(:citations, :column)
      t.string  :line_number unless column_exists?(:citations, :line_number)
      t.string  :record_number unless column_exists?(:citations, :record_number)

      # digital/film specifics
      t.string  :image_url   unless column_exists?(:citations, :image_url)
      t.string  :image_frame unless column_exists?(:citations, :image_frame)
      t.string  :roll        unless column_exists?(:citations, :roll)
      t.string  :enumeration_district unless column_exists?(:citations, :enumeration_district)

      # catch-all when nothing else fits
      t.string  :locator     unless column_exists?(:citations, :locator)
    end

    unless index_exists?(:citations, [:source_id, :citable_type, :citable_id, :volume, :folio, :page], name: :idx_citations_locator)
      add_index :citations, [:source_id, :citable_type, :citable_id, :volume, :folio, :page], name: :idx_citations_locator
    end
  end
end


