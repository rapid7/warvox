Web::Application.routes.draw do

  resources :dial_jobs
  resources :dial_results
  resources :providers

  match '/dial_jobs/:id/run'         => 'dial_jobs#run', :as => :run_dial_job
  match '/dial_results/:id/view'     => 'dial_results#view', :as => :view_dial_result
  match '/dial_results/:id/analyze'  => 'dial_results#analyze', :as => :analyze_dial_result
  match '/dial_results/:id/reanalyze'  => 'dial_results#reanalyze', :as => :reanalyze_dial_result      
  match '/dial_results/:id/purge'    => 'dial_results#purge', :as => :purge_dial_result    

  match '/analyze/:id/resource/:result_id/:type' => 'analyze#resource', :as => :resource_analyze
  match '/analyze/:id/view'    => 'analyze#view', :as => :view_analyze
  match '/analyze/:id/show'    => 'analyze#show', :as => :show_analyze  
  match '/analyze'             => 'analyze#index'
    
  match '/about'               => 'home#about'
  match '/home/about'          => 'home#about'
  
  root :to => "home#index"

end
