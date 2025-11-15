class AddUniqueIndexesOnSlugs < ActiveRecord::Migration[7.1]

    def change
    # Repeat for any tables that have a slug
    add_index :awards, "LOWER(slug)", unique: true, name: "index_awards_on_lower_slug"
     add_index :soldiers, "LOWER(slug)", unique: true, name: "index_soldiers_on_lower_slug"
    
     add_index :wars,     "LOWER(slug)", unique: true, name: "index_wars_on_lower_slug"
    
     add_index :battles,     "LOWER(slug)", unique: true, name: "index_battles_on_lower_slug"
   
    add_index :categories,     "LOWER(slug)", unique: true, name: "indexes_categories_on_lower_slug"
    
    add_index :burials,     "LOWER(slug)", unique: true, name: "indexes_burials_on_lower_slug"
    
    add_index :cemeteries,     "LOWER(slug)", unique: true, name: "indexes_cemeteries_on_lower_slug"
    
    add_index :censuses,     "LOWER(slug)", unique: true, name: "indexes_censuses_on_lower_slug"
    add_index :medals,     "LOWER(slug)", unique: true, name: "indexes_medals_on_lower_slug"
    add_index :newsletters,     "LOWER(slug)", unique: true, name: "indexes_newsletters_on_lower_slug"
    
    add_index :soldier_medals,     "LOWER(slug)", unique: true, name: "indexes_soldier_medals_on_lower_slug"
    
    add_index :sources,     "LOWER(slug)", unique: true, name: "indexes_sources_on_lower_slug"
  end
end
