ActionController::Routing::Routes.draw do |map|
  map.resources :campaign_user_roles

  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Here's a sample route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  map.connect 'mypeople',:controller=>'cart_items',:action=>'list',:id=>nil
  map.connect 'mypeople/:action/:id',:controller=>'cart_items'

  map.connect 'volunteers/calendar/:year/:month', :controller=>'volunteer_events', :action=>'calendar'
  map.connect 'volunteers/:action/:id', :controller=>'volunteer_events'

  map.root :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "sessions", :action=>"new"
  map.forgot_password '/forgot_password', :controller => 'users', :action => 'forgot_password'
  map.reset_password '/reset_password/:activation_code/', :controller => 'users', :action => 'reset_password', :activation_code => nil
  map.list_users '/users/list',:controller=>'users',:action=>'list'
  map.new_user '/users/new',:controller=>'users',:action=>'new'
  map.new_user '/users/edit',:controller=>'users',:action=>'edit'
  map.resources :users, :member => { :suspend => :put, :unsuspend => :put, :purge => :delete }

  map.resource :session
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  # map.connect ':controller/service.wsdl', :action => 'wsdl'

  # ActionController::AbstractRequest.relative_url_root = "/manager"

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
