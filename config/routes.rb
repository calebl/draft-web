Rails.application.routes.draw do
  mount Blazer::Engine, at: 'blazer'

  devise_for :user

  resources :stories do
    resources :writing_sessions
    resource :outline, on: :member do
      resources :outline_items
    end
  end

  root to: 'home#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
