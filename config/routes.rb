
# config/routes.rb
Rails.application.routes.draw do
  get 'index/show'
  get 'index/edit'
  get 'index/new'
  # Root + health
  root "articles#index"
  get "up" => "rails/health#show", as: :rails_health_check

  # Silence Chrome DevTools probe (returns empty 204 JSON)
  get "/.well-known/appspecific/com.chrome.devtools.json",
      to: proc { [204, { "Content-Type" => "application/json" }, ["{}"]] }
# config/routes.rb
resources :soldiers do
  collection { get :search, defaults: { format: :json } }
end
# config/routes.rb
resources :involvements, only: [:create, :destroy]
resources :soldiers do
  collection { get :search }
end
resources :units do
  collection { get :search }
end

# config/routes.rb
get "/sources/autocomplete", to: "sources#autocomplete"

resources :involvements, only: [:create, :destroy]
get "/soldiers/search", to: "soldiers#search"
get "/health", to: "health#show"

resources :sources do
  get :autocomplete, on: :collection
  member { patch :regenerate_slug; post :create_citation }
end
  # Articles
  resources :articles do
    patch :regenerate_slug, on: :member
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

  # Soldiers
  resources :soldiers do
    get :search, on: :collection
    patch :regenerate_slug, on: :member
  end
  resources :soldiers do
    resources :awards, only: [:create, :destroy]
    resources :soldier_medals, only: [:create, :destroy]
  end

  resources :medals, only: [:index, :show]  # catalog
  resources :wars, :battles, :cemeteries, :articles, :sources

  resources :cemeteries do
  get :burials, on: :member
end

# config/routes.rb
resources :involvements, only: [:create, :destroy]
get "soldiers/search", to: "soldiers#search"

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

  # Taxonomy & joins
  resources :categories
  resources :categorizations, only: [:create, :destroy]
  resources :involvements,    only: [:create, :destroy]
  # resources :soldiers do
  #   collection get {:search}
  # end
  resources :involvements, only: [:create, :destroy]

  # Lookups
  get "lookups/citables", to: "lookups#citables"

  # Other resources
  resources :cemeteries
end

