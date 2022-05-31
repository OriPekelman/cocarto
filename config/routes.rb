Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root "main#index"

  scope "(:locale)", locale: /en|fr/ do
    resources :layers
    resources :fields
    resources :row_contents
    resources :territory_categories
    resources :territories do
      collection do
        post "search"
      end
    end
    get "/layers/:id/schema" => "layers#schema"
    get "/:locale" => "dashboard#index"
  end
end
