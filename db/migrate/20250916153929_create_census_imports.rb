class CreateCensusImports < ActiveRecord::Migration[7.1]
  def change
    create_table :census_imports do |t|
      t.string :relationshiptohead
      t.string :firstname
      t.string :lastname
      t.string :sex
      t.string :birthlikedate
      t.string :birthlikeplacetext
      t.string :birthcounty
      t.string :birthcountry
      t.string :chrdate
      t.string :chrplacetext
      t.string :residencedate
      t.string :location
      t.string :residenceplacetext
      t.string :residenceplacecounty
      t.string :residenceplacecountry
      t.string :age
      t.string :householdid
      t.string :booknumber
      t.string :linenumber
      t.string :page
      t.string :piecefolio
      t.string :regnumber
      t.string :marriagelikedate
      t.string :marriagelikeplacetext
      t.string :deathlikedate
      t.string :deathlikeplacetext
      t.string :burialdate
      t.string :burialplacetext
      t.string :fatherfullname
      t.string :fatherlast
      t.string :motherfullname
      t.string :motherlast
      t.string :spousefullname
      t.string :spouselast
      t.string :childrenfullname1
      t.string :childrenfullname2
      t.string :childrenfullname3
      t.string :childrenfullname4
      t.string :childrenfullname5
      t.string :childrenfullname6
      t.string :childrenfullname7
      t.string :childrenfullname8
      t.string :childrenfullname9
      t.string :childrenfullname10
      t.string :childrenfullname11
      t.string :childrenfullname12
      t.string :otherfullname1
      t.string :otherfullname2
      t.string :otherfullname3
      t.string :otherfullname4
      t.string :otherfullname5
      t.string :otherfullname6
      t.string :otherfullname7
      t.string :otherfullname8
      t.string :otherfullname9
      t.string :otherfullname10
      t.string :otherfullname11
      t.string :otherfullname12
      t.string :otherfullname13
      t.string :otherfullname14
      t.string :otherfullname15
      t.string :otherfullname16
      t.string :otherfullname17
      t.timestamps
    end
    add_index :census_imports, :firstname
    add_index :census_imports, :lastname
  end
end
