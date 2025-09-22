
# config/routes.rb
Rails.application.routes.draw do
  # Root + health
  root "articles#index"
  get "up" => "rails/health#show", as: :rails_health_check

  # Silence Chrome DevTools probe (returns empty 204 JSON)
  get "/.well-known/appspecific/com.chrome.devtools.json",
      to: proc { [204, { "Content-Type" => "application/json" }, ["{}"]] }

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

  # Soldiers
  resources :soldiers do
    get :search, on: :collection
    patch :regenerate_slug, on: :member
  end

  # Sources (single consolidated block)
  resources :sources do
    get   :autocomplete,   on: :collection
    patch :regenerate_slug, on: :member
    patch :toggle_common,   on: :member
    post  :create_citation, on: :member
  end

  # Censuses (read-only for now)
  resources :censuses, only: [:index, :show]

  # Taxonomy & joins
  resources :categories
  resources :categorizations, only: [:create, :destroy]
  resources :involvements,    only: [:create, :destroy]

  # Lookups
  get "lookups/citables", to: "lookups#citables"

  # Other resources
  resources :cemeteries
end

