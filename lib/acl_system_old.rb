# See <a href="http://wiki.rubyonrails.com/rails/show/LoginGeneratorACLSystem">http://wiki.rubyonrails.com/rails/show/LoginGeneratorACLSystem</a>

module ACLSystem
  include UserSystem

  # This module wires itself into the LoginSystem authorize? method.  You
  # should use the normal:
  #
  #   before_filter :login_required
  #
  # or to leave some actions unprotected:
  #
  #   before_filter :login_required, :except => [ :list, :show ]
  #

  protected

  # Authorizes the user for an action.
  # This works in conjunction with the UserController.
  # The UserController loads the User object.
  def authorize?(user, id)
    # As copied from the RoR wiki:
    required_perm = "%s/%s" % [ params['controller'], params['action'] ]

    #if user.authorized? required_perm
      #return true
    #end

    #return false
    
    # As adapted for an Access Denial List

    if user.prohibited?(params['controller'], params['action'], id, session[:volunteer_sign_in])
      return false
    end
    
#    if user.prohibited? required_perm, id
      #logger.debug "user prohibited"
#      return false
#    elsif user.prohibited_controller?(params['controller'], params['action'], id)
#      return false
#    elsif user.prohibited_action?(params['controller'], params['action'], id)
#      return false
#    end
    
    return true
  end
  
  # Returns true or false if the user is logged in.
  # Preloads @current_user with the user model if they're logged in.
  def logged_in?
    # logger.debug "checking logged_in?"
    (@current_user ||= session[:user] ? User.find_by_id(session[:user].id) : :false).is_a?(User)
  end
  
  # Accesses the current user from the session.
  def current_user
    # logger.debug "called current_user"
    @current_user if logged_in?
  end
  
  # Store the given user in the session.
  def current_user=(new_user)
    session[:user] = new_user.nil? ? nil : new_user
    @current_user = new_user
    # logger.debug @current_user
  end
  
  # Inclusion hook to make #current_user and #logged_in?
  # available as ActionView helper methods.
  def self.included(base)
    base.send :helper_method, :current_user, :logged_in?
  end
  
end