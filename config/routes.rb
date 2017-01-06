Rails.application.routes.draw do
  resources :jrs
  root "jrs#index"
	get "/search" => "jrs#search", as: "search"
	get "/search/:query" => "jrs#search"
end
