Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :layers do
    resources :points
  end
  resources :fields
  resources :points
  resources :row_contents
end
