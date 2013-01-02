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

  match  '/projects/:project_id/results'          => 'jobs#results', :as => :results
  match  '/projects/:project_id/results/:id'      => 'jobs#view_results', :as => :view_results
  match  '/projects/:project_id/results/:id/analyze'  => 'jobs#analyze_job', :as => :analyze_job
  match  '/projects/:project_id/results/:id/reanalyze'  => 'jobs#reanalyze_job', :as => :reanalyze_job




  match '/projects/:project_id/analyze'             => 'analyze#index', :as => :analyze
  match '/calls/:result_id/:type'                   => 'analyze#resource', :as => :resource_analyze
  match '/projects/:project_id/analyze/:id/view'    => 'analyze#view', :as => :view_analyze

  match '/projects/:project_id/analyze/:job_id/:call_id/matches'    => 'analyze#view_matches', :as => :view_matches

  resources :settings
  resources :providers
  resources :users
  resources :projects
  resources :jobs
  resources :calls

  match '/about'               => 'home#about', :as => :about
  match '/help'                => 'home#help',  :as => :help
  match '/check'               => 'home#check', :as => :check


  root :to => "projects#index"
end
