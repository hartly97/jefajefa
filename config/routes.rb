# config/routes.rb
Rails.application.routes.draw do
  # root "articles#index"  # uncomment if/when you want a homepage

  # Health
  get "up" => "rails/health#show", as: :rails_health_check

  # Silence Chrome DevTools probe (returns empty 204 JSON)
  get "/.well-known/appspecific/com.chrome.devtools.json",
      to: proc { [204, { "Content-Type" => "application/json" }, ["{}"]] }

  # Articles
  resources :articles do
    patch :regenerate_slug, on: :member
  end

  # DNA
  resources :dnas

  # Soldiers (single block)
  resources :soldiers do
    collection do
      get :search, defaults: { format: :json }   # /soldiers/search.json
    end
    patch :regenerate_slug, on: :member

    # Nested mini-endpoints
    resources :awards, only: [:create, :destroy]
    resources :soldier_medals, only: [:create, :destroy]
  end

  # Involvements (AJAX add/remove)
  resources :involvements, only: [:create, :destroy]

  # Units (search endpoint)
  resources :units do
    collection { get :search }
  end

  # Sources (single consolidated block)
  resources :sources do
    get   :autocomplete,    on: :collection
    patch :regenerate_slug, on: :member
    patch :toggle_common,   on: :member
    post  :create_citation, on: :member
  end

  # Medals, Battles, Wars, Awards
  resources :medals  do
    patch :regenerate_slug, on: :member
  end
  resources :battles do
    patch :regenerate_slug, on: :member
  end
  resources :wars do
    patch :regenerate_slug, on: :member
  end
  resources :awards do
    patch :regenerate_slug, on: :member
  end

  # Censuses
  resources :censuses do
    patch :regenerate_slug, on: :member
  end

  # Cemeteries (single block)
  resources :cemeteries do
    get :burials, on: :member
  end

  # Newsletters & Books
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

  # Lookups
  get "lookups/citables", to: "lookups#citables"
end
