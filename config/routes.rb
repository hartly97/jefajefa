# config/routes.rb
Rails.application.routes.draw do
  # ---- Root ----
  root "articles#index"

  # ---- Articles ----
  resources :articles do
    patch :regenerate_slug, on: :member
  end

  # ---- Awards ----
  resources :awards do
    patch :regenerate_slug, on: :member
  end

  # ---- Battles ----
  resources :battles do
    patch :regenerate_slug, on: :member
  end

  #----- Burials -----
  resources :burials, only: [:index, :show]


  #----Categories ----
  resources :categories, only: %i[index show] do
    collection do
      get :topics
      get :sources
      get :locations
    end
  end


  # Taxonomy & joins
  resources :categories
  resources :categorizations, only: [:create, :new, :destroy]

  # ---- Censuses ----
  resources :censuses do
    patch :regenerate_slug, on: :member
  end


  # ---- Cemeteries & Burials ----
  # Nested: index/new/create handled under the cemetery
  resources :cemeteries do
    patch :regenerate_slug, on: :member
    resources :burials
  end

  # Standalone edits for an individual burial
  resources :burials, only: [:show, :edit, :update, :destroy]


  # ---- DNA ----
  resources :dnas

  # ---- Medals ----
  resources :medals do
    patch :regenerate_slug, on: :member
  end

  # ---- Involvements (AJAX) ----
  resources :involvements, only: [:create, :destroy], defaults: { format: :json }

  # ---- Newsletters & Books ----
  resources :newsletters do
    patch :regenerate_slug, on: :member
  end
  resources :books do
    collection do
      get :remedybook
      get :thumbnails
    end
  end
  get "welcome/apothecary", to: "welcome#apothecary"

  # ---- Soldiers ----
  resources :soldiers do
    collection do
      get :search, defaults: { format: :json }  # /soldiers/search.json
    end
    patch :regenerate_slug, on: :member
  end

  # ---- Sources ----
  resources :sources do
    collection { get :autocomplete }
    member do
      patch :regenerate_slug
      patch :toggle_common
      post  :create_citation
    end
  end

  resources :sources do
    member do
      patch :regenerate_slug
      post  :create_citation
      patch :toggle_common
    end
    collection { get :autocomplete }
  end

  # ---- Units ----
  resources :units do
    collection { get :search }
  end

  # ---- Wars ----
  resources :wars do
    patch :regenerate_slug, on: :member
  end

  # ---- SoldierMedals (bridge) ----
  resources :soldier_medals, only: [:create, :destroy]

  # ---- Health & DevTools noise ----
  get "up" => "rails/health#show", as: :rails_health_check
  get "/.well-known/appspecific/com.chrome.devtools.json",
      to: proc { [204, { "Content-Type" => "application/json" }, ["{}"]] }
end
