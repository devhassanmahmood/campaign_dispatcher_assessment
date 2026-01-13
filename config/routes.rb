Rails.application.routes.draw do
  root "campaigns#index"
  
  resources :campaigns do
    member do
      post :start_dispatch
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
