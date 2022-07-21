Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  scope "(:locale)", locale: Regexp.union(I18n.available_locales.map(&:to_s)) do
    devise_for :users

    root "main#index"

    resources :layers do
      member do
        get :schema
        get :geojson
      end
      resources :rows
    end
    resources :maps do
      resources :layers, only: [:new]
    end
    resources :fields
    resources :territory_categories
    resources :territories do
      collection do
        post "search"
      end
    end
    get "/:locale" => "main#index"
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
