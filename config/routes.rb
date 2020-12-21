Rails.application.routes.draw do
  root "habits#index"
  post "/callback", to: "line_bot#callback"
  resources :habits
end
