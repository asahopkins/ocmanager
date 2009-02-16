# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  layout  'user'

  before_filter :login_required, :except=>[:new, :create, :destroy]

  # render new.rhtml
  def new
    @page_title = "Login"
  end

  def create
    logout_keeping_session!
    user = User.authenticate(params[:login], params[:password])
    if user
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      self.current_user = user
      user.activation_code = nil
      # user.logged_in_at = Time.now
      user.save!
      new_cookie_flag = (params[:remember_me] == "1")
      handle_remember_cookie! new_cookie_flag
      redirect_to :controller=>"campaigns", :action => 'select'
      # redirect_back_or_default('/')
      flash[:notice] = "Logged in successfully"
    else
      note_failed_signin
      @login       = params[:login]
      @remember_me = params[:remember_me]
      render :action => 'new'
    end
  end

  def destroy
    current_user.current_campaign = nil if current_user
    current_user.save if current_user
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_to :action => 'new'
  end

  def name
    "Users"
  end 

  def set_volunteer_terminal
    session[:volunteer_sign_in] = true
    redirect_to :controller=>"volunteer_events", :action=>"welcome"
  end

protected
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = "Couldn't log you in as '#{params[:login]}'"
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end


end
