Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root "main#index"

  scope "(:locale)", locale: Regexp.union(I18n.available_locales.map(&:to_s)) do
    resources :layers do
      member do
        get :schema
        get :geojson
      end
    end
    resources :maps
    resources :fields
    resources :rows
    resources :territory_categories
    resources :territories do
      collection do
        post "search"
      end
    end
    get "/:locale" => "dashboard#index"
  end
end
