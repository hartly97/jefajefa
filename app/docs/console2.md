Step 1 — Try a minimal routes file

Temporarily replace your entire config/routes.rb with this:

Rails.application.routes.draw do
  root "articles#index"
  resources :articles
end


Then run:

bin/rails routes


If this works: the problem is in the original file (likely an invisible char or a specific block). Go to Step 2.

If this still fails: the error isn’t routes—something else is raising during boot. Check the exact error line/file shown in the backtrace.

Step 2 — Add sections back one at a time

Restore your file incrementally, running bin/rails routes after each addition. Use this order:

health + devtools JSON

soldiers block

sources block

categories / categorizations / involvements

lookups

cemeteries / wars / battles / medals

This will pinpoint the exact block that triggers the error.

Step 3 — Hunt for invisible characters

Sometimes a pasted file contains non-printing Unicode that Ruby chokes on.

Run:

# show line numbers and reveal non-printables (^ and M- escapes)
cat -n -v config/routes.rb

# also show all non-ASCII bytes in hex
xxd -g 1 -c 256 config/routes.rb


Look for weird escapes like M- or ^@ around commas, quotes, or do/end. If you see them, retype that line manually or delete & retype the block.

Step 4 — Confirm only one declaration per resource

Double-check no duplicates elsewhere (sometimes a merge leaves a second block below):

grep -nE 'resources :articles|resources :soldiers|resources :sources' config/routes.rb


Each should appear once. If you need extra routes, put them inside that single block:

resources :soldiers do
  collection { get :search }
  patch :regenerate_slug, on: :member
end

resources :sources do
  patch :regenerate_slug, on: :member
  post  :create_citation, on: :member
end

Step 5 — Final clean version (paste back after the minimal test passes)
Rails.application.routes.draw do
  # Root + health
  root "articles#index"
  get "up" => "rails/health#show", as: :rails_health_check

  # Silence Chrome DevTools probe (returns 204)
  get "/.well-known/appspecific/com.chrome.devtools.json",
      to: proc { [204, { "Content-Type" => "application/json" }, ["{}"]] }

  # Articles
  resources :articles do
    patch :regenerate_slug, on: :member
  end

  # Soldiers
  resources :soldiers do
    collection { get :search }           # /soldiers/search
    patch :regenerate_slug, on: :member
  end

  # Sources
  resources :sources do
    patch :regenerate_slug, on: :member
    post  :create_citation, on: :member
  end

  # Taxonomy & joins
  resources :categories
  resources :categorizations, only: [:create, :destroy]
  resources :involvements,   only: [:create, :destroy]

  # Lookups
  get "lookups/citables", to: "lookups#citables"

  # Other resources
  resources :cemeteries
  resources :wars
  resources :battles
  resources :medals
end


If it still errors after Step 1 (with the minimal file), paste the exact error message and the file/line shown—that’ll tell us if a different initializer or file is blowing up during routes evaluation.