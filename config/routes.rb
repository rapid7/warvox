Web::Application.routes.draw do

  match "login" => "user_sessions#new", :as => "login"
  match "logout" => "user_sessions#destroy", :as => "logout"

  resources :user_sessions

  match  '/projects/:project_id/all'                    => 'projects#index', :as => :all_projects


  match  '/jobs/dial'            => 'jobs#new_dialer',   :as => :new_dialer_job
  match  '/projects/:project_id/jobs/dial'            => 'jobs#new_dialer',   :as => :new_dialer_project_job
  match  '/jobs/dialer'          => 'jobs#dialer',       :as => :dialer_job

  match  '/jobs/analyze'         => 'jobs#new_analyze',  :as => :new_analyze_job
  match  '/projects/:project_id/jobs/analyze'         => 'jobs#new_analyze',  :as => :new_analyze_project_job
  match  '/jobs/analyzer'        => 'jobs#analyzer',     :as => :analyzer_job

  match  '/projects/:project_id/jobs/identify'        => 'jobs#new_identify', :as => :new_identify_project_job
  match  '/jobs/identifier'      => 'jobs#identifier',   :as => :identifier_job

  match  '/jobs/:id/stop'        => 'jobs#stop',         :as => :stop_job
  match  '/jobs/:id/calls/purge' => "jobs#purge_calls",  :as => :purge_calls_job

  match  '/projects/:project_id/calls/purge' => "jobs#purge_calls",  :as => :purge_calls_project_job

  match  '/projects/:project_id/scans'          => 'jobs#results', :as => :results
  match  '/projects/:project_id/scans/:id'      => 'jobs#view_results', :as => :view_results
  match  '/projects/:project_id/scans/:id/analyze'    => 'jobs#analyze_job', :as => :analyze_job
  match  '/projects/:project_id/scans/:id/reanalyze'  => 'jobs#reanalyze_job', :as => :reanalyze_job

  match  '/projects/:project_id/calls/analyze'      => 'jobs#analyze_project', :as => :analyze_project_job
  match  '/projects/:project_id/calls/identify'     => 'jobs#identify_project', :as => :identify_project_job


  match '/projects/:project_id/analyze'             => 'analyze#index', :as => :analyze
  match '/call/:result_id.:type'                   => 'analyze#resource', :as => :resource_analyze
  match '/projects/:project_id/analyze/:id/view'    => 'analyze#view', :as => :view_analyze

  match '/projects/:project_id/analyze/:job_id/:call_id/matches'    => 'analyze#view_matches', :as => :view_matches
  match '/projects/:project_id/analyze/:call_id/matches'    => 'analyze#view_matches', :as => :view_matches_project

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
