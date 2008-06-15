# ---------------------------------------------------------------------------
# 
# Open Campaigns Manager
# Copyright (C) 2008 Asa S. Hopkins, Open Campaigns
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
# ---------------------------------------------------------------------------

class UserController < ApplicationController
  layout  'user'
  # model   :user

#  caches_page :login
  
  before_filter :login_required, :except=>[:login, :logout, :welcome, :not_available, :forgot_password]

  before_filter :check_user_campaigns, :only=>[:edit_role, :inactivate, :update_roles]

  verify :method => :post, :only => [ :set_volunteer_terminal ],
         :redirect_to => { :controller=>:campaigns, :action => :start_here }

  filter_parameter_logging :password

  def name
    "Users"
  end 

  def list
    @cur_array = Array.new
    @user_array = Array.new
    for comm_id in session[:user].manager_campaigns
      @cur_array << CampaignUserRole.find(:all,:conditions=>["campaign_id = :comm",{:comm=>comm_id}])
    end
    @cur_array.flatten!
    @cur_array.each {|cur|
      @user_array << cur.user
      }
    @user_array.uniq!
    @user_pages, @users = paginate_collection @user_array, :per_page => 10, :page=>params[:page]
    render(:layout => 'layouts/manager')
  end

# TODO: the initial superuser creation process needs checking
  def login
    @count = User.count
    if current_user and current_user.logged_in_at.to_time > 1.hour.ago
      redirect_to :controller=>"campaigns", :action => 'select'
      return
    end
    @request = request
    if @mobile and request.get?
      render :action=>"login_mobile", :layout=>"mobile" and return
    end
    if generate_blank
      return
    end
    params['user']['login'] = params['user']['email']
    #@user = User.new(params['user'])
    if (self.current_user = User.authenticate(params['user']['login'], params['user']['password']) and current_user.update_attributes({"logged_in_at"=>DateTime.now,"verified"=>true}))
      logger.debug current_user.id
      #session[:cart] = Cart.new
      flash[:notice] = l(:user_login_succeeded)
      redirect_to :controller=>"campaigns", :action => 'select'
      return
    elsif User.count==0 # generate the superuser account
      @count = User.count
      logger.debug "count = 0"
      params['user'].delete('form')
      temp_user_hash = {'password'=>generate_password()}
      params['user'].update(temp_user_hash)
      @user = User.new(params['user'])
      begin
        User.transaction do
          @user.new_password = true
          if @user.save!
            logger.debug @user
            Role.load_roles
            logger.debug "back from load_roles"
            reset_and_update_permissions()
            logger.debug "permissions set"
            # this is a bit funny because campaign 1 doesn't exist yet (by assumption)
            @superuser = Role.find(:first,:conditions=>["name = 'Super User'"])
            cur_hash = {"campaign_id"=>1, "user_id"=>@user.id, "role_id"=>@superuser.id } 
            logger.debug cur_hash
            @cur = CampaignUserRole.new(cur_hash)
            logger.debug "cur about to be saved: "+cur_hash.to_s
            @cur.save!
            logger.debug @cur
            key = @user.generate_security_token
            url = url_for(:action => 'login')
            #url = url_for(:action => 'welcome')
            #url += "?user[id]=#{@user.id}&key=#{key}"
            UserNotify.deliver_signup(@user, params['user']['password'], url)
            flash[:notice] = l(:user_signup_succeeded)
            # TODO: test this cache expiration on a fresh database
            expire_page(:controller => "user", :action => 'login')
            redirect_to :controller => 'user', :action=> 'login', :protocol=>@@protocol
          end
        end
      rescue
        flash.now['message'] = l(:user_confirmation_email_error)
      end
    else
      @login = params['user']['login']
      flash.now['message'] = l(:user_login_failed)
    end
  end

  def not_available
    render_without_layout
  end

  def new
    if session[:user].superuser?
      @campaigns = Campaign.find(:all)
    else
      @campaigns = Array.new
      session[:user].campaign_user_roles.each {|cur|
        if cur.role.rank<=2
          @campaigns << cur.campaign
        end
      }
    end
    @request = request
    return if generate_blank_with_full_layout
    params['user'].delete('form')
    
    #check if the user has been defined a role
    has_role = false
    for campaign in @campaigns
      unless params['user_campaign']['role'][campaign.id.to_s]=="0"
        has_role = true
      end
    end
    if session[:user].superuser? or has_role
      temp_user_hash = {'login' => params['user']['email'], 'password'=>generate_password(),'created_by'=>session[:user].id}
      params['user'].update(temp_user_hash)
      @user = User.new(params['user'])
      @user.treasurer_info = Hash.new
      #logger.debug @user
      begin
        User.transaction do
          #loggger.debug @user
          @user.new_password = true
          if @user.save
            #logger.debug @user
            for campaign in @campaigns
              unless params['user_campaign']['role'][campaign.id.to_s]=="0"
                logger.debug "make role for campaign: "+campaign.name
                if params['user_campaign']['role'][campaign.id.to_s].to_i <= 3
                  api_token = @user.class.hashed(@user.salted_password + Time.now.to_i.to_s + rand.to_s)
                else
                  api_token = nil
                end
                financial = false
                # logger.debug "about to assign financial"
                unless params['user_campaign']['financial'].nil? or params['user_campaign']['financial'][campaign.id.to_s].nil?
                  # logger.debug "financial hash exists"
                  if params['user_campaign']['financial'][campaign.id.to_s].to_i == 1
                    # logger.debug "financial is true"
                    financial = true
                  end
                end
                # logger.debug "financial assigned"
                cur_hash = {"campaign_id"=>campaign.id, "user_id"=>@user.id, "role_id"=>params['user_campaign']['role'][campaign.id.to_s],"created_by"=>session[:user].id,:api_token=>api_token}
                logger.debug cur_hash
                @cur = CampaignUserRole.new(cur_hash)
                @cur.save!
                @cur.update_attribute(:financial,financial)
              end
            end
            key = @user.generate_security_token
            url = url_for(:action => 'login')
            #url = url_for(:action => 'welcome')
            #url += "?user[id]=#{@user.id}&key=#{key}"
            UserNotify.deliver_signup(@user, params['user']['password'], url)
            flash[:notice] = l(:user_signup_succeeded)
            redirect_to :controller => 'admin', :action=> 'index', :protocol=>@@protocol
          end
        end
      rescue
        flash.now['message'] = l(:user_confirmation_email_error)
      end
    else
      flash[:warning] = "Must give the new user a role."
      redirect_to :controller => 'user', :action=> 'new', :protocol=>@@protocol
    end
  end  

  def logout
    #session[:user] = nil
    #session[:cart] = nil
    current_user.current_campaign = nil if current_user
    current_user.save if current_user
    reset_session
    redirect_to :action => 'login', :protocol=>@@protocol
  end

  def change_password
    @force_change = true  
    @request = request
    return if generate_filled_in_plain_layout
    params['user'].delete('form')
    #logger.debug @user
    #logger.debug @user.email
    User.transaction do
      @user.change_password(params['user']['password'], params['user']['password_confirmation'])
      #logger.debug "salt = "+@user.salt
      #logger.debug @user.id
      @user.save!
      #logger.debug "salt = "+@user.salt
      UserNotify.deliver_change_password(@user, params['user']['password'])
      flash.now['notice'] = l(:user_updated_password, "#{@user.email}")
    end
#    rescue
#      flash.now['message'] = l(:user_change_password_email_error)
  end

  def forgot_password
    # Always redirect if logged in
    if user?
      flash['message'] = l(:user_forgot_password_logged_in)
      redirect_to :action => 'change_password', :protocol=>@@protocol
      return
    end

    @request = request
    # Render on :get and render
    return if generate_blank

    # Handle the :post
    if params['user']['email'].empty?
      flash.now['message'] = l(:user_enter_valid_email_address)
    elsif (@user = User.find_by_email(params['user']['email'])).nil?
      flash.now['message'] = l(:user_email_address_not_found, "#{params['user']['email']}")
    else
      User.transaction do
        key = @user.generate_security_token
        url = url_for(:action => 'change_password')
        url += "?user[id]=#{@user.id}&key=#{key}"
        UserNotify.deliver_forgot_password(@user, url)
        flash['notice'] = l(:user_forgotten_password_emailed, "#{params['user']['email']}")
        unless user?
          redirect_to :action => 'login', :protocol=>@@protocol
          return
        end
        redirect_back_or_default :action => 'welcome'
      end
    end
  # rescue
  #   flash.now['message'] = l(:user_forgotten_password_email_error, "#{params['user']['email']}")
  end

  def edit
    @request = request
    return if generate_filled_in
    if params['user']['form']
      form = @params['user'].delete('form')
      @params = params
      begin
        case form
        when "edit"
          changeable_fields = ['firstname', 'lastname']
          @params = @params['user'].delete_if { |k,v| not changeable_fields.include?(k) }
          @user.attributes = @params
          @user.save!
        when "generate_token"
          cur = CampaignUserRole.find(:first,:conditions=>["user_id=:user AND campaign_id = :campaign_id",{:user=>@user.id,:campaign_id=>@params[:campaign_id]}])
          cur.update_attributes(:api_token=>@user.class.hashed(@user.salted_password + Time.now.to_i.to_s + rand.to_s))
        when "treasurer_token"
          committee_id = @params[:committee][:id]
          @user.treasurer_info ||= Hash.new
          @user.treasurer_info[committee_id.to_i] = Array.new
          @user.treasurer_info[committee_id.to_i][0] = @params['user']['treasurer_login']
          @user.treasurer_info[committee_id.to_i][1] = @params['user']['treasurer_token'].strip
          @user.save
        when "change_password"
          change_password
        when "delete"
          delete
        else
          raise "unknown edit action"
        end
      end
    end
    render(:layout => 'layouts/manager')
  rescue
    flash[:warning] = "There was an error."
    render(:layout => 'layouts/manager')
  end

  def edit_roles
    @user = User.find(params[:user_id])
    @campaigns = Campaign.find(:all,:conditions=>["id IN (:ids)",{:ids=>session[:user].manager_campaigns}])
    #@role_id = @user.role(@campaign)
    render(:layout => 'layouts/manager')
  end
  
  def update_roles
    @user = User.find(params[:user_id])
    unless @user.superuser?
      CampaignUserRole.transaction do
        for campaign_id in session[:user].manager_campaigns
          @cur = CampaignUserRole.find(:first, :conditions=>["user_id = :user AND campaign_id = :comm",{:user=>@user.id, :comm=>campaign_id}])
          campaign = Campaign.find(campaign_id)
          logger.debug "params[:user_campaign][:role]["+campaign_id.to_s+"] = " + params[:user_campaign][:role][campaign_id.to_s]
          # logger.debug params[:user_campaign][:financial][campaign_id.to_s].to_s
          unless params[:user_campaign][:financial].nil?
            if params[:user_campaign][:financial][campaign_id.to_s].to_i == 1
              financial = true
            else
              financial = false
            end
          else
            financial = false
          end
          # if financial
          #   logger.debug "financial is true"
          # else
          #   logger.debug "financial is false"
          # end
          if @cur.nil?
            logger.debug "@cur.nil? is true"
            unless params[:user_campaign][:role][campaign_id.to_s].to_s=="0"
              if params[:user_campaign][:role][campaign_id.to_s].to_i <= 3 #TODO: update to be flexible for role ids
                api_token = @user.class.hashed(@user.salted_password + Time.now.to_i.to_s + rand.to_s)
              else
                api_token = nil
              end
              new_cur_hash = {"user_id"=>@user.id, "campaign_id"=> campaign_id, "role_id"=>params[:user_campaign][:role][campaign_id.to_s],"created_by"=>session[:user].id, :api_token=>api_token}
              @cur = CampaignUserRole.new(new_cur_hash)
              @cur.save!
              @cur.update_attribute(:financial,financial)
            end
          else
            logger.debug "@cur.nil? is false"
            if params['user_campaign']['role'][campaign.id.to_s].to_i <= 3 #TODO: update to be flexible for role ids
              if @cur.api_token.nil? 
                api_token = @user.class.hashed(@user.salted_password + Time.now.to_i.to_s + rand.to_s)
              else 
                api_token = @cur.api_token
              end
            else
              api_token = nil
            end
            if params[:user_campaign][:role][campaign_id.to_s].to_s=="0"
              params[:user_campaign][:role][campaign_id.to_s]="8"
              logger.debug "changed role to 8"
            end
            if params[:user_campaign][:role][campaign_id.to_s].to_s == @user.role(campaign).to_s
              logger.debug "no change to role"
            else
              new_cur_hash = {"user_id"=>@user.id, "campaign_id"=> campaign_id, "role_id"=>params[:user_campaign][:role][campaign_id.to_s],"updated_by"=>session[:user].id, :api_token=>api_token}
              unless @cur.update_attributes(new_cur_hash)
                raise
              end
            end
            @cur.update_attribute(:financial,financial)
          end
          logger.debug "User "+@user.name+" has updated roles"
          flash[:notice] = "User "+@user.name+" has updated roles"
        end
      end
    else
      flash[:notice] = "User "+@user.name+" is a SuperUser, and roles cannot be changed."
    end
    redirect_to :action=>"list", :protocol=>@@protocol
  rescue
    flash[:warning] = 'Something went wrong.'
	  redirect_to :controller=>"user", :action=>"list", :protocol=>@@protocol
  end

  def inactivate
    @user = User.find(params[:user_id])
    logger.debug @user.id
    logger.debug @campaign.id
    unless @user.superuser?
      @cur = CampaignUserRole.find(:first, :conditions=>["user_id = :user AND campaign_id = :campaign",{:user=>@user.id, :campaign=>@campaign.id}])
      inact_role = Role.find(:first,:conditions=>["name = :inactive",{:inactive=>"Inactive"}])
      new_cur_hash = {"user_id"=>@user.id, "campaign_id"=> @campaign.id, "role_id"=>inact_role.id, "updated_by"=>session[:user].id}
      if @cur.update_attributes(new_cur_hash)
      else
        raise
      end
      flash[:notice] = "User "+@user.name+" has been inactivated for campaign: "+@campaign.name
    else
      flash[:notice] = "User "+@user.name+" is a SuperUser, and roles cannot be changed."
    end
    redirect_to :action=>"list", :protocol=>@@protocol
  # rescue
  #   flash[:notice] = 'Something went wrong.'
  #     redirect_to :controller=>"user", :action=>"list", :protocol=>@@protocol
  end

  def delete
    @user = session[:user]
    begin
      if UserSystem::CONFIG[:delayed_delete]
        User.transaction(@user) do
          key = @user.set_delete_after
          url = url_for(:action => 'restore_deleted')
          url += "?user[id]=#{@user.id}&key=#{key}"
          UserNotify.deliver_pending_delete(@user, url)
        end
      else
        destroy(@user)
      end
      logout
    rescue
      flash.now['message'] = l(:user_delete_email_error, "#{@user['email']}")
      redirect_back_or_default :action => 'welcome'
    end
  end

  def restore_deleted
    @user = session[:user]
    @user.deleted = 0
    if not @user.save
      flash.now['notice'] = l(:user_restore_deleted_error, "#{@user['login']}")
      redirect_to :action => 'login', :protocol=>@@protocol
    else
      redirect_to :action => 'welcome', :protocol=>@@protocol
    end
  end

  def welcome
    if params[:key].nil? or params[:user].nil? or params[:user][:id].nil?
      redirect_to :action=>"not_available", :protocol=>@@protocol
      return
    end
    unless session[:user] or session[:user] = User.authenticate_by_token(params[:user][:id], params[:key])
      redirect_to :action=>"not_available", :protocol=>@@protocol
      return
    end
    @user = session[:user]
    @force_change = true  
    logger.debug "@user.id = "+@user.id.to_s
    @request = request
    return if generate_filled_in_plain_layout
    params['user'].delete('form')
    logger.debug "@user.id = "+@user.id.to_s
    begin
      User.transaction(@user) do
        @user.change_password(params['user']['password'], params['user']['password_confirmation'])
        if @user.save
          UserNotify.deliver_change_password(@user, params['user']['password'])
          flash.now['notice'] = l(:user_updated_password, "#{@user.email}")
          redirect_to :action=>"logout", :protocol=>@@protocol
        end
      end
    rescue
      flash.now['message'] = l(:user_change_password_email_error)
    end
  end

  def set_volunteer_terminal
    session[:volunteer_sign_in] = true
    redirect_to :controller=>"volunteer_events", :action=>"welcome"
  end

  protected

  def destroy(user)
    UserNotify.deliver_delete(user)
    flash['notice'] = l(:user_delete_finished, "#{user['login']}")
    user.destroy()
  end

  def protect?(action)
    if ['login', 'forgot_password'].include?(action)
      return false
    else
      return true
    end
  end

  # Generate a template user for certain actions on get
  def generate_blank
    case @request.method
    when :get
      @user = User.new
      render
      return true
    end
    return false
  end

  # Generate a template user for certain actions on get
  def generate_blank_with_full_layout
    case @request.method
    when :get
      @user = User.new
      render(:layout => 'layouts/manager')
      return true
    end
    return false
  end

  # Generate a template user for certain actions on get
  def generate_filled_in
    @user = session[:user]
    case @request.method
    when :get
      render(:layout => 'layouts/manager')
      return true
    end
    return false
  end

  def generate_filled_in_plain_layout
    @user = session[:user]
    case @request.method
    when :get
      render
      return true
    end
    return false
  end
  
  # this should be defunct soon
#    def signup
#      return if generate_blank
#      params['user'].delete('form')
#      @user = User.new(params['user'])
#      begin
#        User.transaction(@user) do
#          @user.new_password = true
#          if @user.save
#            key = @user.generate_security_token
#            url = url_for(:action => 'welcome')
#            url += "?user[id]=#{@user.id}&key=#{key}"
#            UserNotify.deliver_signup(@user, params['user']['password'], url)
#            flash['notice'] = l(:user_signup_succeeded)
#            redirect_to :action => 'login', :protocol=>@@protocol
#          end
#        end
#      rescue
#        flash.now['message'] = l(:user_confirmation_email_error)
#      end
#    end  
  #####  

  protected
  
  def check_user_campaigns
    # @campaign = Campaign.find(current_user.current_campaign)
    logger.debug session[:user].manager_campaigns.to_s
    logger.debug current_user.current_campaign.to_s
    if session[:user].manager_campaigns.include?(current_user.current_campaign)
      @campaign = Campaign.find(current_user.current_campaign)
      if params[:campaign_id]
        if params[:campaign_id].to_s != @campaign.id.to_s
          raise
        end
      end
    else
      @campaign = nil
      render :partial=>"user/not_available"
    end
  # rescue
  #   flash[:notice] = 'Something went wrong.'
  #   redirect_to :controller=>"user", :action=>"list", :protocol=>@@protocol
  end

  
  
end
