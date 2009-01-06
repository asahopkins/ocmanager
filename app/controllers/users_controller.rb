class UsersController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  # include AuthenticatedSystem
  
  # Protect these actions behind an admin login
  # before_filter :admin_required, :only => [:suspend, :unsuspend, :destroy, :purge]
  before_filter :find_user, :only => [:suspend, :unsuspend, :destroy, :purge]
  
  before_filter :login_required, :except=>[:forgot_password, :reset_password_email, :reset_password, :set_password]

  # render new.rhtml
  def new
    @user = User.new
  end
 
  # render forgot_password.html.erb
  def forgot_password
    @user = User.new
  end

  def create
    logout_keeping_session!
    @user = User.new(params[:user])
    @user.register! if @user && @user.valid?
    success = @user && @user.valid?
    if success && @user.errors.empty?
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end

  def reset_password_email
    logout_keeping_session!
    user = User.find_by_email(params[:user][:email])
    case
    when user
      user.reset_password_process
      flash[:notice] = "An email has been sent to #{params[:user][:email]} with instructions."
      redirect_to '/login'
    else
      flash[:error]  = "We couldn't find a user with that email address -- perhaps you used a different address?"
      redirect_to '/forgot_password'
    end
  end
  
  def reset_password
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && params[:email] == user.email
      # user.new_password_ok!
      @user = user
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    when user && params[:email] != user.email
      flash[:error] = "The activation code or email was incorrect.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else 
      flash[:error]  = "We couldn't find a user with that activation code -- check your email?"
      redirect_back_or_default('/')
    end
  end
  
  def set_password
    logout_keeping_session!
    @user = User.find_by_activation_code(params[:user][:activation_code]) unless params[:user][:activation_code].blank?
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    @user.save! if @user && @user.valid?
    success = @user && @user.valid?
    if success && @user.errors.empty?
      @user.activation_code = nil
      @user.save!
      flash[:notice] = "Password set! Please sign in to continue."
      redirect_to '/login'
    else
      if !@user.errors.empty?
        flash[:error] = @user.errors.full_messages.to_s
      else
        flash[:error]  = "We couldn't change your password, sorry. Please try again, or contact an admin (link is above)."
      end
      redirect_to :action=>"reset_password", :params=>{:activation_code=>params[:user][:activation_code], :email=>@user.email}
    end
  end

  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Signup complete! Please sign in to continue."
      redirect_to '/login'
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else 
      flash[:error]  = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default('/')
    end
  end

  def suspend
    @user.suspend! 
    redirect_to users_path
  end

  def unsuspend
    @user.unsuspend! 
    redirect_to users_path
  end

  def destroy
    @user.delete!
    redirect_to users_path
  end

  def purge
    @user.destroy
    redirect_to users_path
  end
  
  # There's no page here to update or destroy a user.  If you add those, be
  # smart -- make sure you check that the visitor is authorized to do so, that they
  # supply their old password along with a new one to update it, etc.

protected
  def find_user
    @user = User.find(params[:id])
  end
end
