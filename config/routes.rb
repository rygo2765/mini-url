Rails.application.routes.draw do
  resources :urls
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Error page
  get "/error_no_urls", to: "urls#error_no_urls", as: "error_no_urls"

  # Custom Routes
  get "/myurls", to: "urls#my_urls", as: "my_urls"
  get "/myurls/:short_url", to: "urls#show_visits", as: "show_visits_by_short_url"
  get "/:short_url", to: "urls#redirect_to_target"
  get "/visits/:short_url", to: "urls#show_visits", as: "show_visits"
  get "/generate/:short_url", to: "urls#show", as: "generate"



  # Defines the root path route ("/")
  root "urls#new"
end
