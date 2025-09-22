Find & kill the duplicates
1) Show duplicates in routes.rb
# See if the same resource is declared multiple times
grep -nE 'resources :articles|resources :soldiers|resources :sources' config/routes.rb


If any show up more than once, consolidate to a single block per resource and move all member/collection routes inside that one block.

2) Count routes per controller (to spot which area is bloated)
bin/rails routes | awk 'NR>1 {print $(NF)}' | cut -d'#' -f1 | sort | uniq -c | sort -nr


You’ll get counts like:

  24 sources
  20 soldiers
  18 articles
  ...


Anything unusually high tells you where duplicates remain.

3) Inspect a specific set
# All routes that hit SourcesController
bin/rails routes | grep 'sources#'

# Helpers that start with source_
bin/rails routes | awk 'NR>1 {print $1}' | grep '^source'

4) Quick sanity for each main resource
bin/rails routes | grep 'articles#' | wc -l     # expect ~8
bin/rails routes | grep 'soldiers#' | wc -l     # expect ~9
bin/rails routes | grep 'sources#'  | wc -l     # expect ~9

5) Make sure only ONE declaration per resource

Use this consolidated pattern (example for sources):

resources :sources do
  patch :regenerate_slug, on: :member
  post  :create_citation, on: :member
end


…and remove any other resources :sources blocks elsewhere in the file.

Common “gotchas”

A stray second resources :articles near the bottom.

Declaring resources :soldiers once and again for search; instead, use:

resources :soldiers do
  collection { get :search }
  patch :regenerate_slug, on: :member
end