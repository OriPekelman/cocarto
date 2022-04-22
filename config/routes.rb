Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root "layers#index"

  resources :layers
  resources :fields
  resources :row_contents
  get "/layers/:id/schema" => "layers#schema"
end
