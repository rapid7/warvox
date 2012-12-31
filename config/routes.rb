Web::Application.routes.draw do

  resources :projects
  resources :settings
  resources :providers

  resources :users
  match "login" => "user_sessions#new", :as => "login"
  match "logout" => "user_sessions#destroy", :as => "logout"
  resources :user_sessions

  match  '/projects/:project_id/all'                    => 'projects#index', :as => :all_projects

  match  '/projects/:project_id/jobs'                   => 'dial_jobs#index', :as => :dial_jobs
  match  '/projects/:project_id/jobs/:id/run'           => 'dial_jobs#run', :as => :run_dial_job
  match  '/projects/:project_id/jobs/:id/stop'          => 'dial_jobs#stop', :as => :stop_dial_job
  match  '/projects/:project_id/jobs/new'               => 'dial_jobs#new', :as => :new_dial_job
  delete '/projects/:project_id/jobs/:id'               => 'dial_jobs#destroy'

  match  '/projects/:project_id/results/'               => 'dial_results#index', :as => :dial_results
  match  '/projects/:project_id/results/:id/view'       => 'dial_results#view', :as => :view_dial_result
  match  '/projects/:project_id/results/:id/analyze'    => 'dial_results#analyze', :as => :analyze_dial_result
  match  '/projects/:project_id/results/:id/reanalyze'  => 'dial_results#reanalyze', :as => :reanalyze_dial_result
  match  '/projects/:project_id/results/:id/purge'      => 'dial_results#purge', :as => :purge_dial_result
  delete '/projects/:project_id/results/:id'            => 'dial_results#destroy'

  match '/projects/:project_id/analyze'             => 'analyze#index', :as => :analyze
  match '/projects/:project_id/analyze/:id/resource/:result_id/:type' => 'analyze#resource', :as => :resource_analyze
  match '/projects/:project_id/analyze/:id/view'    => 'analyze#view', :as => :view_analyze
  match '/projects/:project_id/analyze/:dial_result_id/matches'    => 'analyze#view_matches', :as => :view_matches
  match '/projects/:project_id/analyze/:id/show'    => 'analyze#show', :as => :show_analyze

  match '/projects/:project_id/providers'           => 'providers#index', :as => :project_providers


  match '/projects/:project_id/about'    => 'home#about', :as => :project_about

  match '/projects/:project_id/settings'    => 'settings#index', :as => :project_settings
  match '/about'               => 'home#about'
  match '/home/about'          => 'home#about'
  match '/help'                => 'home#help'
  match '/check'               => 'home#check', :as => :check


  root :to => "projects#index"
end
