Rails.application.routes.draw do
  root 'xml_app#index'
  
  get 'dashboard', to: 'xml_app#dashboard'
  get 'xml_app/:key', to: 'xml_app#show', as: 'xml_page'
  
  # Authentication routes (implement as needed)
  # get 'login', to: 'sessions#new'
  # post 'login', to: 'sessions#create'
  # delete 'logout', to: 'sessions#destroy'
end
