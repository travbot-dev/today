Rails.application.routes.draw do
  resource :session
  resources :users, only: %i[new create show]
  resources :api_tokens, only: %i[index create destroy]
  resources :todos, only: %i[index create destroy] do
    collection do
      patch :reorder
    end
    member do
      patch :complete
      patch :move
    end
  end
  resources :events do
    collection do
      post :import_preview
      post :import
      get :load_more
    end
    member do
      get :export
    end
  end
  resources :projects, only: %i[index new create edit update show] do
    collection do
      patch :reorder
    end
    member do
      patch :toggle_complete
    end
    resource :badge, only: [ :create ], controller: "project_badges"
    resources :thoughts, only: [ :create, :destroy ], controller: "project_thoughts"
    resources :resources, only: [ :create, :destroy ], controller: "project_resources"
    resources :journal_entries, only: [ :create, :destroy ], controller: "project_journal_entries"
    resources :milestones, only: [ :create, :update, :destroy, :show ], controller: "project_milestones" do
      collection do
        patch :reorder
      end
      member do
        patch :toggle_complete
      end
      resources :todos, only: [ :create ], controller: "milestone_todos"
    end
  end
  resources :agents, only: :create

  # TRMNL e-ink display preview
  get "trmnl/preview", to: "trmnl_preview#show", as: :trmnl_preview

  # Streaming voice command API endpoints
  namespace :api do
    namespace :gemini do
      post "token", to: "tokens#create"
    end
    resources :todos, only: :create do
      collection do
        patch :bulk_move
      end
    end

      # Versioned API for external access via tokens
    namespace :v1 do
      get "docs", to: "docs#show"
      get "trmnl/dashboard", to: "trmnl#dashboard"
      get "activity", to: "activity#show"
      get "daily_digest", to: "daily_digest#show"

      resources :projects do
        member do
          patch :toggle_complete
        end
        resources :milestones do
          member do
            patch :toggle_complete
          end
        end
        resources :thoughts
        resources :resources
        resources :journal_entries
      end

      resources :todos do
        collection do
          get :week_review
        end
        member do
          patch :complete
          patch :move
        end
      end
    end
  end

  # MCP (Model Context Protocol) server for ChatGPT integration
  post "/mcp", to: "mcp#handle"
  get "/.well-known/oauth-protected-resource", to: "well_known#oauth_protected_resource"

  root "sessions#new"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
