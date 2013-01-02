Web::Application.routes.draw do





  match "login" => "user_sessions#new", :as => "login"
  match "logout" => "user_sessions#destroy", :as => "logout"

  resources :user_sessions

  match  '/projects/:project_id/all'                    => 'projects#index', :as => :all_projects


  match  '/jobs/dial'          => 'jobs#new_dialer', :as => :new_dialer_job
  match  '/jobs/dialer'          => 'jobs#dialer', :as => :dialer_job
  match  '/jobs/analyze'       => 'jobs#new_analyzer', :as => :new_analyzer_job
  match  '/jobs/analyzer'       => 'jobs#analyzer', :as => :analyzer_job
  match  '/jobs/:id/stop'          => 'jobs#stop', :as => :stop_job


  match  '/projects/:project_id/calls/'               => 'calls#index', :as => :calls
  match  '/projects/:project_id/calls/:id/view'       => 'calls#view', :as => :view_call
  match  '/projects/:project_id/calls/:id/analyze'    => 'calls#analyze', :as => :analyze_call
  match  '/projects/:project_id/calls/:id/reanalyze'  => 'calls#reanalyze', :as => :reanalyze_call
  match  '/projects/:project_id/calls/:id/purge'      => 'calls#purge', :as => :purge_call
  delete '/projects/:project_id/calls/:id'            => 'calls#destroy'

  match '/projects/:project_id/analyze'             => 'analyze#index', :as => :analyze
  match '/projects/:project_id/analyze/:id/resource/:result_id/:type' => 'analyze#resource', :as => :resource_analyze
  match '/projects/:project_id/analyze/:id/view'    => 'analyze#view', :as => :view_analyze
  match '/projects/:project_id/analyze/:call_id/matches'    => 'analyze#view_matches', :as => :view_matches
  match '/projects/:project_id/analyze/:id/show'    => 'analyze#show', :as => :show_analyze


  resources :settings
  resources :providers
  resources :users
  resources :projects
  resources :jobs

  match '/about'               => 'home#about', :as => :about
  match '/help'                => 'home#help',  :as => :help
  match '/check'               => 'home#check', :as => :check


  root :to => "projects#index"
end
