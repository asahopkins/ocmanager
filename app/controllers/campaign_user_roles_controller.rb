class CampaignUserRolesController < ApplicationController
  layout 'manager'
  before_filter :get_campaign
  
  # GET /campaign_user_roles
  # GET /campaign_user_roles.xml
  # def index
  #   @campaign_user_roles = CampaignUserRole.find(:all)
  # 
  #   respond_to do |format|
  #     format.html # index.html.erb
  #     format.xml  { render :xml => @campaign_user_roles }
  #   end
  # end
  # 
  # # GET /campaign_user_roles/1
  # # GET /campaign_user_roles/1.xml
  # def show
  #   @campaign_user_role = CampaignUserRole.find(params[:id])
  # 
  #   respond_to do |format|
  #     format.html # show.html.erb
  #     format.xml  { render :xml => @campaign_user_role }
  #   end
  # end
  # 
  # # GET /campaign_user_roles/new
  # # GET /campaign_user_roles/new.xml
  # def new
  #   @campaign_user_role = CampaignUserRole.new
  # 
  #   respond_to do |format|
  #     format.html # new.html.erb
  #     format.xml  { render :xml => @campaign_user_role }
  #   end
  # end

  # GET /campaign_user_roles/1/edit
  def edit
    @page_title = "User Roles :: Edit"
    @campaign_user_role = CampaignUserRole.find(params[:id])
    unless @current_user.manager_campaigns.include?(@campaign_user_role.campaign_id)
      # TODO test this
      flash[:error] = "You do not have permission to edit this role."
      redirect_to :controller=>:users, :action=>:list
    end
    @campaign = @campaign_user_role.campaign
    @user = @campaign_user_role.user
    @roles = Role.find(:all, :conditions=>"roles.rank != 1").sort {|a,b| a.rank <=> b.rank}
  end

  # POST /campaign_user_roles
  # POST /campaign_user_roles.xml
  # def create
  #   @campaign_user_role = CampaignUserRole.new(params[:campaign_user_role])
  # 
  #   respond_to do |format|
  #     if @campaign_user_role.save
  #       flash[:notice] = 'CampaignUserRole was successfully created.'
  #       format.html { redirect_to(@campaign_user_role) }
  #       format.xml  { render :xml => @campaign_user_role, :status => :created, :location => @campaign_user_role }
  #     else
  #       format.html { render :action => "new" }
  #       format.xml  { render :xml => @campaign_user_role.errors, :status => :unprocessable_entity }
  #     end
  #   end
  # end

  # PUT /campaign_user_roles/1
  # PUT /campaign_user_roles/1.xml
  def update
    @campaign_user_role = CampaignUserRole.find(params[:id])
    @user = @campaign_user_role.user
    if @user.superuser?
      flash[:error] = "A Superuser's roles may not be editted."
      redirect_to :controller=>:users, :action=>:list
    end
    unless @current_user.manager_campaigns.include?(@campaign_user_role.campaign_id)
      # TODO test this
      flash[:error] = "You do not have permission to edit this role."
      redirect_to :controller=>:users, :action=>:list
    end
    respond_to do |format|
      if @campaign_user_role.update_attributes(params[:campaign_user_role]) and @user.update_attribute(:updated_at, Time.now)
        flash[:notice] = "#{@user.name}\'s role was successfully updated."
        format.html { redirect_to :controller=>:users, :action=>:list }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @campaign_user_role.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /campaign_user_roles/1
  # DELETE /campaign_user_roles/1.xml
  # def destroy
  #   @campaign_user_role = CampaignUserRole.find(params[:id])
  #   @campaign_user_role.destroy
  # 
  #   respond_to do |format|
  #     format.html { redirect_to(campaign_user_roles_url) }
  #     format.xml  { head :ok }
  #   end
  # end
end
