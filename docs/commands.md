## Console sanity checks

```ruby
# Categories
Article.first.categories.pluck(:name)
Soldier.first.categories.pluck(:name)

# Citations
Article.first.sources.pluck(:title)
Soldier.first.sources.pluck(:title)

# Involvements
War.first.soldiers.pluck(:last_name)
Battle.first.soldiers.pluck(:last_name)
Medal.first.soldiers.pluck(:last_name)