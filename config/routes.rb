XmlFramework::Engine.routes.draw do
  root 'xml_app#index'

  get 'dashboard', to: 'xml_app#dashboard'
  get 'xml_app/:key', to: 'xml_app#show', as: 'xml_page'

  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  get 'jsondata', to: 'json_data#show'
  post 'datapost', to: 'data_post#create'
  delete 'datapost', to: 'data_post#destroy'
  post 'ajaxupdate', to: 'ajax_update#create'
  post 'filters', to: 'filters#create'
  post 'reports', to: 'reports#create'
end
