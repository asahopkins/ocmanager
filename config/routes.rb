ActionController::Routing::Routes.draw do |map|
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Here's a sample route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  map.connect 'mypeople',:controller=>'cart_items',:action=>'list',:id=>nil
  map.connect 'mypeople/:action/:id',:controller=>'cart_items'

  map.connect 'volunteers/calendar/:year/:month', :controller=>'volunteer_events', :action=>'calendar'
  map.connect 'volunteers/:action/:id', :controller=>'volunteer_events'

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  map.connect '', :controller => "user", :action=>"login"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  ActionController::AbstractRequest.relative_url_root = "/manager"

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
end
