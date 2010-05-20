ActionController::Routing::Routes.draw do |map|

  map.root :controller => "magazine"
  map.connect 'more', :controller => 'magazine', :action => 'more'
  map.connect '/classifications/more', :controller => 'classifications', :action => 'more'
  
  # wtf was I thinking? Needs to be refactored.
  map.connect 'entries/:id/disliked', :controller => 'classifications', :action => 'disliked', :conditions => { :method => :post }
  map.connect 'entries/:id/liked', :controller => 'classifications', :action => 'liked', :conditions => { :method => :post }

  map.connect 'entries/:id/read', :controller => 'magazine', :action => "read", :conditions => { :method => :post }

 
  map.resources :subscriptions
  map.resource :user_session
  map.resource :account, :controller => "users"
  map.resources :classifications

  map.connect '/login', :controller => 'user_sessions', :action => 'new'
  map.connect '/logout', :controller => 'user_sessions', :action => 'destroy'
  map.connect '/nil', :controller => 'magazine', :action => 'nothing'
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
