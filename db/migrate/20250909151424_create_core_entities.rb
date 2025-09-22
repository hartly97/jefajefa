


class CreateCoreEntities < ActiveRecord::Migration[7.1]
  def change
    # 1) Base tables (no FKs first)
    create_table :articles do |t|
      t.string :title, null: false
      t.text   :body
      t.string :slug,  null: false
      t.timestamps
    end
    add_index :articles, :slug, unique: true

    create_table :cemeteries do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
    end
    add_index :cemeteries, :slug, unique: true

    create_table :sources do |t|
      t.string :title, null: false
      t.text   :details
      t.string :repository
      t.string :link_url
      t.string :slug, null: false
      t.timestamps
    end
    add_index :sources, :title
    add_index :sources, :slug, unique: true

    create_table :wars do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
    end
    add_index :wars, :slug, unique: true

    # 2) Dependent tables (FKs after parents)
    create_table :battles do |t|
      t.string :name, null: false
      t.date   :date
      t.string :slug, null: false
      t.references :war, null: true, foreign_key: true  # optional war
      t.timestamps
    end
    add_index :battles, :slug, unique: true

    create_table :soldiers do |t|
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :birthcity
      t.string :birthstate
      t.string :birthcountry
      t.string :deathcity
      t.string :deathstate
      t.string :deathcountry
      t.references :cemetery, null: true, foreign_key: true
      t.string :slug, null: false
      t.timestamps
    end
    add_index :soldiers, [:last_name, :first_name]
    add_index :soldiers, :slug, unique: true

    # 3) Catalogs without FKs (order here doesn’t matter now)
    create_table :medals do |t|
      t.string  :name, null: false
      t.integer :year
      t.string  :slug, null: false
      t.timestamps
    end
    add_index :medals, :slug, unique: true
  end
end


