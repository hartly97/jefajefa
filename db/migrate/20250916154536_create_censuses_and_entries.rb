class CreateCensusesAndEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :censuses do |t|
      t.string  :country,   null: false       # "England", etc.
      t.integer :year,      null: false       # 1841, 1851...
      t.string  :district
      t.string  :subdistrict
      t.string  :place
      t.string  :piece
      t.string  :folio
      t.string  :page
      t.string  :booknumber
      t.string  :image_url     # SmugMug URL (preferred)
      t.string  :slug, null: false
      t.references :source, foreign_key: true, null: true
      t.timestamps
    end
    add_index :censuses, [:country, :year, :district, :subdistrict, :piece, :folio, :page], name: :idx_censuses_locator
    add_index :censuses, :slug, unique: true

  create_table :census_entries do |t|
  # Explicitly target the plural table name for the FK
  t.references :census,  null: false, foreign_key: { to_table: :censuses }
  t.references :soldier, null: true,  foreign_key: { to_table: :soldiers }

  t.string :householdid
  t.string :linenumber
  t.integer :household_position

  t.string :firstname
  t.string :lastname
  t.string :sex
  t.string :age

  t.string :relationshiptohead
  t.string :occupation

  t.string :birthlikedate
  t.string :birthlikeplacetext
  t.string :birthcounty
  t.string :birthcountry

  t.string :residencedate
  t.string :residenceplacetext
  t.string :residenceplacecounty
  t.string :residenceplacecountry
  t.string :location

  t.string :regnumber
  t.string :page_ref

  t.text   :notes
  t.timestamps
end

add_index :census_entries, [:census_id, :householdid, :linenumber], name: :idx_census_entries_loc
add_index :census_entries, [:lastname, :firstname]

  end
end
