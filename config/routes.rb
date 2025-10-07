
# config/routes.rb
Rails.application.routes.draw do
  
  # Root + health
  # root "articles#index"
  
  # Articles
  resources :articles do
    patch :regenerate_slug, on: :member
  end

  get "up" => "rails/health#show", as: :rails_health_check

  resources :dnas
  # Silence Chrome DevTools probe (returns empty 204 JSON)
  get "/.well-known/appspecific/com.chrome.devtools.json",
      to: proc { [204, { "Content-Type" => "application/json" }, ["{}"]] }

      # Soldiers
resources :soldiers do
  collection { get :search, defaults: { format: :json } }
end
get "/soldiers/search", to: "soldiers#search"
 # Soldiers
  resources :soldiers do
    get :search, on: :collection
    patch :regenerate_slug, on: :member
  end
  resources :soldiers do
    resources :awards, only: [:create, :destroy]
    resources :soldier_medals, only: [:create, :destroy]
  end

# Involvements
resources :involvements, only: [:create, :destroy]

resources :units do
  collection { get :search }
end

# config/routes.rb
resources :involvements, only: [:create, :destroy]
get "soldiers/search", to: "soldiers#search", defaults: { format: :json }  # you already have this

# get "/sources/autocomplete", to: "sources#autocomplete"

# Option B — Read-only pages (list + detail) plus your endpoints
resources :sources, only: [:index, :show] do
  get :autocomplete, on: :collection
  member { patch :regenerate_slug; post :create_citation }
end

 

  # Medals, Battles, Wars, Awards
  resources :medals  do
    patch :regenerate_slug, on: :member
  end
  resources :battles do
    patch :regenerate_slug, on: :member
  end
  resources :wars    do
    patch :regenerate_slug, on: :member
  end
  resources :awards  do
    patch :regenerate_slug, on: :member
  end
  
  resources :censuses do
    patch :regenerate_slug, on: :member
  end

 
  resources :medals, only: [:index, :show]  # catalog
  resources :wars, :battles, :cemeteries, :sources

  resources :cemeteries do
  get :burials, on: :member
end

# config/routes.rb
resources :involvements, only: [:create, :destroy]
get "soldiers/search", to: "soldiers#search", defaults: { format: :json }


# get "censuses/search", to: "censuses#search"
  # Sources (single consolidated block)
  resources :sources do
    get   :autocomplete,   on: :collection
    patch :regenerate_slug, on: :member
    patch :toggle_common,   on: :member
    post  :create_citation, on: :member
  end

  # Censuses (read-only for now)
  #  resources :censuses
  # , only: [:index, :show]
# config/routes.rb
resources :newsletters do
  patch :regenerate_slug, on: :member
end

 resources :books

  get 'books/remedybook'
  get 'books/thumbnails'
  get 'welcome/apothecary'

  # Taxonomy & joins
  resources :categories
  resources :categorizations, only: [:create, :destroy]
  resources :involvements,    only: [:create, :destroy]


  # Lookups
  get "lookups/citables", to: "lookups#citables"

  # Other resources
  resources :cemeteries
end

