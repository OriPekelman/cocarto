Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  scope "(:locale)", locale: Regexp.union(I18n.available_locales.map(&:to_s)) do
    devise_for :users, skip: :invitations, controllers: {registrations: "users/registrations"}

    devise_scope :user do
      # Just the wanted subset of invitable routes
      get "/users/invitation/accept" => "devise/invitations#edit", :as => :accept_user_invitation
      put "/users/invitation" => "devise/invitations#update", :as => :user_invitation
    end

    unauthenticated do
      root "pages#presentation"
    end

    authenticated :user do
      root "maps#index", as: :authenticated_root
    end

    resources :maps, except: [:edit] do
      resources :layers, only: [:new]
      resources :access_groups, only: [:index, :create, :update, :destroy], shallow: true
    end
    resources :layers, except: [:index, :new, :edit] do
      resources :rows, only: [:new, :create, :edit, :update, :destroy] do
        collection do
          resource :import, only: [:show, :create], controller: :import
        end
      end
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
    get "share/:token", to: "access_groups#enter_by_link", as: "share_link"
    get "layers/:id/geojson", to: redirect("layers/%{id}.geojson")
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
