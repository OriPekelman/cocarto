Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  scope "(:locale)", locale: Regexp.union(I18n.available_locales.map(&:to_s)) do
    devise_for :users, skip: :invitations, controllers: {registrations: "users/registrations", sessions: "users/sessions"}

    devise_scope :user do
      # Just the wanted subset of invitable routes
      get "/users/invitation/accept" => "devise/invitations#edit", :as => :accept_user_invitation
      put "/users/invitation" => "devise/invitations#update", :as => :user_invitation
    end

    unauthenticated do
      root "pages#presentation"
    end

    authenticated :user do
      root "maps#index", as: :user_root
    end

    resources :maps, except: [:edit] do
      resources :layers, only: [:new]
      resources :user_roles, only: [:index, :create, :update, :destroy], shallow: true
      resources :map_tokens, only: [:index, :create, :update, :destroy], shallow: true
      namespace :import do
        resources :operations, only: [:new, :create, :show], shallow: true, namespace: :import
      end
    end
    resources :layers, except: [:index, :new] do
      resources :rows, only: [:new, :create, :edit, :update, :destroy]
      member do
        get "/mvt/:z/:x/:y/", action: :mvt
      end
    end
    resources :fields, only: [:create, :update, :destroy]

    resources :territory_categories, only: [:index, :show]
    resources :territories, only: [:show] do
      collection do
        get "search"
      end
    end

    get "/legal" => "pages#legal"
    get "/legal/conditions" => "pages#legal_conditions"
    get "/legal/data" => "pages#legal_data"
    get "/presentation" => "pages#presentation"
    get "share/:token", to: "maps#shared", as: "map_shared"
    get "layers/:id/geojson", to: redirect("layers/%{id}.geojson")
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  if Rails.env.development?
    mount GoodJob::Engine, at: "good_job"
  else
    authenticate :user, ->(user) { user.admin? } do
      mount GoodJob::Engine, at: "good_job"
    end
  end
end
