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

class GroupsController < ApplicationController
  layout 'manager'

  before_filter :get_campaign

  before_filter :check_campaign,:only=>[:list,:new,:create,:index]
  before_filter :check_group, :only=>[:show,:edit,:update,:destroy,:remove_member, :add_group_to_cart]
  
  def index
    list
    render :action => 'list', :params=>{:campaign_id=>@campaign.id}
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @group_pages, @groups = paginate :groups, :per_page => 25, :conditions=>["campaign_id=:campaign",{:campaign=>@campaign.id}], :order=>"name"
  end

  def show
    # TODO: this sort will fail if there are multiple kind of entities represented
    group_members = @group.entities.to_a
    group_members = group_members.sort {|a,b| [a.last_name.to_s, a.name.to_s, a.first_name.to_s] <=> [b.last_name.to_s, b.name.to_s, b.first_name.to_s] }
    @member_pages, @members = paginate_collection group_members, :per_page => 25, :page=>params[:page]
    session[:user].edit_groups?(@campaign) ? @can_edit = true : @can_edit = false
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(params[:group])
    @group.campaign = @campaign
    if @group.save
      flash[:notice] = 'Group was successfully created.'
      redirect_to :action => 'list', :params=>{:campaign_id=>@campaign.id}, :protocol=>@@protocol
    else
      render :action => 'new', :params=>{:campaign_id=>@campaign.id}
    end
  end

  def edit
    #@group = Group.find(params[:id])
  end

  def update
    #@group = Group.find(params[:id])
    if @group.update_attributes(params[:group])
      flash[:notice] = 'Group was successfully updated.'
      redirect_to :action => 'show', :id => @group, :params=>{:campaign_id=>@campaign.id}, :protocol=>@@protocol
    else
      render :action => 'edit', :params=>{:campaign_id=>@campaign.id}
    end
  end

  def remove_member
    @entity = Entity.find(params[:entity_id])
    if @entity.remove_from_group(@group)
      
    else
      flash[:warning] = "Error: could not remove from group"
      redirect_to :action=>'show', :id=>group.id, :protocol=>@@protocol
      return
    end
  end
  
  def add_group_to_cart
    CartItem.add(@group.entities, current_user.id)
  end
  
  def add_cart_to_group
    @group = Group.find(params[:group][:id])
    @campaign = @group.campaign
    if session[:user].active_campaigns.include?(@campaign.id)
    else
      @group = nil
      @campaign = nil
      render :partial=>"user/not_available"
      return
    end
#    @cart = find_cart
    @entities = current_user.entities
    @entities.each do |entity|
      if entity.campaign = @campaign
        entity.add_to_group(@group, params[:group][:role])
      end
    end
    render :update do |page|
      page.replace_html 'flash_notice', "MyPeople added to group: #{@group.name}"
    end
  end

  def destroy
    #Group.find(params[:id]).destroy
    @group.destroy
    redirect_to :action => 'list', :params=>{:campaign_id=>@campaign.id}, :protocol=>@@protocol
  end
  
  protected
  
  def check_campaign
    # unless params[:campaign_id]
    #   params[:campaign_id] = session[:user].active_campaigns.first
    # end
    # @campaign = Campaign.find(params[:campaign_id])
    if current_user.active_campaigns.include?(@campaign.id)
    else
      @campaign = nil
      render :partial=>"user/not_available"
    end
  end
  
  def check_group
    @group = Group.find(params[:id])
    # @campaign = @group.campaign
    if current_user.active_campaigns.include?(@campaign.id) and @campaign.id = @group.campaign_id
      unless params[:group].nil?
        params[:group][:updated_by]=session[:user].id
      end
    else
      @group = nil
      @campaign = nil
      render :partial=>"user/not_available"
    end
  end
  
  
end
