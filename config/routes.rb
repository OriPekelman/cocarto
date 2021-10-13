Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :layers do
    resources :fields
  end
  resources :fields
end
