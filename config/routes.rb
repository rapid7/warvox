Rails.application.routes.draw do
  get "login" => "user_sessions#new", :as => "login"
  get "logout" => "user_sessions#destroy", :as => "logout"

  resources :user_sessions

  get  '/projects/:project_id/all'                    => 'projects#index', :as => :all_projects


  get  '/jobs/dial'            => 'jobs#new_dialer',   :as => :new_dialer_job
  get  '/projects/:project_id/jobs/dial'            => 'jobs#new_dialer',   :as => :new_dialer_project_job
  put  '/jobs/dialer'          => 'jobs#dialer',       :as => :dialer_job

  get  '/jobs/analyze'         => 'jobs#new_analyze',  :as => :new_analyze_job
  get  '/projects/:project_id/jobs/analyze'         => 'jobs#new_analyze',  :as => :new_analyze_project_job
  put  '/jobs/analyzer'        => 'jobs#analyzer',     :as => :analyzer_job

  get  '/projects/:project_id/jobs/identify'        => 'jobs#new_identify', :as => :new_identify_project_job
  put  '/jobs/identifier'      => 'jobs#identifier',   :as => :identifier_job

  get  '/jobs/:id/stop'        => 'jobs#stop',         :as => :stop_job
  post  '/jobs/:id/calls/purge' => "jobs#purge_calls",  :as => :purge_calls_job

  post  '/projects/:project_id/calls/purge' => "jobs#purge_calls",  :as => :purge_calls_project_job

  get  '/projects/:project_id/scans'          => 'jobs#results', :as => :results
  get  '/projects/:project_id/scans/:id'      => 'jobs#view_results', :as => :view_results
  get  '/projects/:project_id/scans/:id/analyze'    => 'jobs#analyze_job', :as => :analyze_job
  get  '/projects/:project_id/scans/:id/reanalyze'  => 'jobs#reanalyze_job', :as => :reanalyze_job

  put  '/projects/:project_id/calls/analyze'      => 'jobs#analyze_project', :as => :analyze_project_job
  put  '/projects/:project_id/calls/identify'     => 'jobs#identify_project', :as => :identify_project_job


  get '/projects/:project_id/analyze'             => 'analyze#index', :as => :analyze
  get '/call/:result_id/:rtype'                   => 'analyze#resource', :as => :resource_analyze
  get '/projects/:project_id/analyze/:id/view'    => 'analyze#view', :as => :view_analyze

  get '/projects/:project_id/analyze/:job_id/:call_id/matches'    => 'analyze#view_matches', :as => :view_matches
  get '/projects/:project_id/analyze/:call_id/matches'    => 'analyze#view_matches', :as => :view_matches_project

  resources :settings
  resources :providers
  resources :users
  resources :projects
  resources :jobs
  resources :calls

  get '/about'               => 'home#about', :as => :about
  get '/help'                => 'home#help',  :as => :help
  get '/check'               => 'home#check', :as => :check

  root :to => "projects#index"
end
