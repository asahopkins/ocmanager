class UsersController < ApplicationController
  layout  'user'
  # Be sure to include AuthenticationSystem in Application Controller instead
  # include AuthenticatedSystem
  
  # Protect these actions behind an admin login
  # before_filter :admin_required, :only => [:suspend, :unsuspend, :destroy, :purge]
  before_filter :find_user, :only => [:suspend, :unsuspend, :destroy, :purge]
  
  before_filter :login_required, :except=>[:forgot_password, :reset_password_email, :reset_password, :set_password, :activate]

  # render new.rhtml
  def new
    if current_user.superuser?
      @campaigns = Campaign.find(:all)
    else
      @campaigns = Array.new
      current_user.campaign_user_roles.each {|cur|
        if cur.role.rank<=2
          @campaigns << cur.campaign
        end
      }
    end
    @user = User.new
  end
 
  # render forgot_password.html.erb
  def forgot_password
    @user = User.new
  end

  def create
    # logout_keeping_session!
    if current_user.superuser?
      @campaigns = Campaign.find(:all)
    else
      @campaigns = Array.new
      current_user.campaign_user_roles.each {|cur|
        if cur.role.rank<=2
          @campaigns << cur.campaign
        end
      }
    end
    has_role = false
    for campaign in @campaigns
      unless params[:user_campaign][:role][campaign.id.to_s]=="0"
        has_role = true
      end
    end
    if current_user.superuser? or has_role
      temp_user_hash = {:login => params[:user][:email], :password=>generate_password(), :created_by=>current_user.id}
      params[:user].update(temp_user_hash)
      params[:user][:password_confirmation] = params[:user][:password]
      @user = User.new(params[:user])
      @user.register! if @user && @user.valid?
      success = @user && @user.valid?
      if success && @user.errors.empty?
        for campaign in @campaigns
          unless params[:user_campaign][:role][campaign.id.to_s]=="0"
            logger.debug "make role for campaign: "+campaign.name
            financial = false
            # logger.debug "about to assign financial"
            unless params[:user_campaign][:financial].nil? or params[:user_campaign][:financial][campaign.id.to_s].nil?
              # logger.debug "financial hash exists"
              if params[:user_campaign][:financial][campaign.id.to_s].to_i == 1
                # logger.debug "financial is true"
                financial = true
              end
            end
            # logger.debug "financial assigned"
            cur_hash = {"campaign_id"=>campaign.id, "user_id"=>@user.id, "role_id"=>params[:user_campaign][:role][campaign.id.to_s],"created_by"=>current_user.id}
            logger.debug cur_hash
            @cur = CampaignUserRole.new(cur_hash)
            @cur.save!
            @cur.update_attribute(:financial,financial)
          end
        end
        redirect_to :controller=>'admin', :action=>'index'
        flash[:notice] = "We're sending an email to #{@user.name} with their activation code."
        return
      end
    end
    flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is below)."
    render :action => 'new'
  end

  def reset_password_email
    logout_keeping_session!
    user = User.find_by_email(params[:user][:email])
    case
    when user
      user.reset_password_process
      flash[:notice] = "An email has been sent to #{params[:user][:email]} with instructions."
      redirect_to :controller=>'sessions', :action=>'new'
    else
      flash[:error]  = "We couldn't find a user with that email address -- perhaps you used a different address?"
      redirect_to :action=>:forgot_password
    end
  end
  
  def reset_password
    logout_keeping_session!
    logger.debug params
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && params[:email] == user.email
      # user.new_password_ok!
      @user = user
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_to :controller=>'sessions', :action=>'new'
    when user && params[:email] != user.email
      flash[:error] = "The activation code or email was incorrect.  Please follow the URL from your email."
      redirect_to :controller=>'sessions', :action=>'new'
    else 
      flash[:error]  = "We couldn't find a user with that activation code -- check your email?"
      redirect_to :controller=>'sessions', :action=>'new'
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
      redirect_to :controller=>'sessions', :action=>'new'
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
      flash[:notice] = "Signup complete! Please sign in to continue. Click \"Edit Account\" to change your password."
      redirect_to :controller=>'sessions', :action=>'new'
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_to :controller=>'sessions', :action=>'new'
    else 
      flash[:error]  = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_to :controller=>'sessions', :action=>'new'
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

  def name
    "Users"
  end 

  def list
    @single = true if params[:id] == "current"
    page = params[:page] || 1
    @cur_array = Array.new
    @user_array = Array.new
    if @single
      @campaign = Campaign.find(current_user.current_campaign)
      # single campaign mode
      @cur_array << CampaignUserRole.find(:all,:conditions=>["campaign_id = :comm",{:comm=>@campaign.id}])
      @cur_array.flatten!
      @cur_array.each {|cur|
        @user_array << cur.user
        }
      @user_array.uniq!
      @user_array.sort! do |a, b|
        a_inactive = 0
        b_inactive = 0
        a_inactive = 1 if a.inactive?(@campaign)
        b_inactive = 1 if b.inactive?(@campaign)
        tmp = a_inactive <=> b_inactive
        if tmp != 0
          tmp
        else
          a.name.upcase <=> b.name.upcase
        end
      end
      @users = paginate_collection @user_array, :per_page => 10, :page=>page      
    else
      # superuser mode
      for comm_id in current_user.manager_campaigns
        @cur_array << CampaignUserRole.find(:all,:conditions=>["campaign_id = :comm",{:comm=>comm_id}])
      end
      @cur_array.flatten!
      @cur_array.each {|cur|
        @user_array << cur.user
        }
      @user_array.uniq!
      @user_array.sort! do |a, b|
        if b.logged_in_at and a.logged_in_at
          b.logged_in_at <=> a.logged_in_at
        else
          b.updated_at <=> a.updated_at
        end
      end
      @users = paginate_collection @user_array, :per_page => 10, :page=>page
    end
    render(:layout => 'layouts/manager')
  end

  def edit
    @user = current_user
  end
  
  def update
    @user = User.find(params[:id])
    @user.update_attributes(params[:user])
    # @user.register! if @user && @user.valid?
    success = @user && @user.valid?
    if success && @user.errors.empty?
      logger.debug "UPDATED"
      redirect_to :controller=>"campaigns", :action=>"start_here"
    else
      logger.debug "NO UPDATE"
      flash[:error]  = "We couldn't make those changes, sorry.  Please try again, or contact an admin (link is below)."
      render :action => 'edit'
    end
    # redirect_to :controller=>"campaigns", :action=>"start_here"
  end


protected
  def find_user
    @user = User.find(params[:id])
  end
    
end
