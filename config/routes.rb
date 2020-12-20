Rails.application.routes.draw do
  root "habits#index"
  resources :habits
end
