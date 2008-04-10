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

class CampaignsController < ApplicationController
  layout 'manager'
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def start_here
    get_campaign
    @page_title = "Start Here"
    if @mobile 
      render :action=>"start_mobile", :layout=>"mobile"
      return
    end
  end

  def list
    @campaign_pages, @campaigns = paginate :campaigns, :per_page => 10
  end

  def select
    if current_user.campaigns.uniq.length == 1
      current_user.current_campaign = current_user.campaigns.first.id
      current_user.save
      redirect_back_or_default(:controller=>'campaigns', :action=>'start_here')
      return
    end
    unless request.post?
      if @mobile 
        render :action=>"select", :layout=>"mobile"
      end      
      return
    end
    current_user.current_campaign = params[:campaign_id]
    current_user.save
    redirect_back_or_default(:controller=>'campaigns', :action=>'start_here')
    # @campaigns = session[:user].active_campaigns
    # logger.debug @campaigns
    # if @campaigns.length==1
    #   redirect_to :controller=>"entities", :action=>"list", :params=>{:campaign_id=>@campaigns[0]}, :protocol=>@@protocol
    # else
    #   @campaign_pages, @campaigns = paginate :campaigns, :per_page => 10      
    # end
  end

  def show
    @campaign = Campaign.find(params[:id])
  end

  def new
    @campaign = Campaign.new
  end

  def create
    @campaign = Campaign.new()
    @campaign.from_emails = []
    address_array = params[:campaign][:from_addresses].split(',')
    address_array.each do |address|
      address.strip!
      @campaign.from_emails << address
    end
    @campaign.from_emails.uniq!
    params[:campaign].delete(:from_addresses)
    @campaign.name = params[:campaign][:name]
    @superusers = User.find(:all,:include=>:campaign_user_roles, :conditions=>["campaign_user_roles.role_id = :super_role", {:super_role=>Role.superuser_id}])
    if @campaign.save
      @superusers.each do |user|
        api_token = user.class.hashed(user.salted_password + Time.now.to_i.to_s + rand.to_s)
        cru = CampaignUserRole.new({:user_id=>user.id,:role_id=>Role.superuser_id,:campaign_id=>@campaign.id,:created_by=>current_user.id,:api_token=>api_token})
        cru.save!
      end
      Dir.mkdir(@@file_path_prefix + @campaign.id.to_s) # creates exported_files directory for this campaign
      flash[:notice] = 'Campaign was successfully created.'
      redirect_to :action => 'list', :protocol=>@@protocol
    else
      render :action => 'new'
    end
  end

  def edit
    @campaign = Campaign.find(params[:id])
    unless @campaign.from_emails.class == Array
      @campaign.from_emails = []
    end
  end

  def update
    @campaign = Campaign.find(params[:id])
    # unless @campaign.from_emails.class == Array
      @campaign.from_emails = []
    # end
    address_array = params[:campaign][:from_addresses].split(',')
    address_array.each do |address|
      address.strip!
      @campaign.from_emails << address
    end
    @campaign.from_emails.uniq!
    @campaign.save
    params[:campaign].delete(:from_addresses)
    if @campaign.update_attributes(params[:campaign])
      flash[:notice] = 'Campaign was successfully updated.'
      redirect_to :action => 'show', :id => @campaign, :protocol=>@@protocol
    else
      render :action => 'edit'
    end
  end

  def destroy
    Campaign.find(params[:id]).destroy
    redirect_to :action => 'list', :protocol=>@@protocol
  end
  
  def edit_tags
    get_campaign
    @tags = @campaign.tags
  end
  
  def destroy_tag
    get_campaign
    @tag = Tag.find(params[:id])
    @dom_id = "tag_"+@tag.id.to_s
    taggings = @tag.taggings
    taggings.each do |tagging|
      tagging.destroy
    end
    @tag.destroy
    expire_fragment(:controller => "campaigns", :action => "tags", :action_suffix => @campaign.id)
    render :update do |page|
      page.remove @dom_id
    end
  end
  
end
