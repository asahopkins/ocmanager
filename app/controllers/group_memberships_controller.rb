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

class GroupMembershipsController < ApplicationController
  
  before_filter :get_campaign
  
# TODO: add before_filters, etc
# TODO: all three .rjs files are identical.  they should just be one file!
  def create
    @user = current_user
    @entity = Entity.find(params[:entity_id])
    # @campaign = @entity.campaign
    if params[:group_id].to_s ==""
      render :partial=>"entities/groups_info", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign), :can_edit_groups=>current_user.edit_groups?(@campaign)}, :protocol=>@@protocol
    else
      @group = Group.find(params[:group_id])
      params[:group][:role].to_s == "" ? role = "Member" : role = params[:group][:role]
      if @group.campaign_id == @campaign.id
        @membership = GroupMembership.new(:entity_id=>@entity.id, :group_id=>@group.id, :role=>role)
        if @membership.save
          @notice = "Successfully added to group: #{@group.name}."
          @success = true
          @protocol = @@protocol
          return
        else
          @notice = "Error adding to group: #{@group.name}."
          flash[:warning] = "Error adding to group: #{@group.name}."
          @success = false
          redirect_to :action=>:show, :id=>@entity.id, :protocol=>@@protocol
          return
        end
      else
        render :partial=>"entities/groups_info", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign), :can_edit_groups=>current_user.edit_groups?(@campaign)}, :protocol=>@@protocol
        return
      end
    end
  end
  
  def update
    @user = current_user
    @membership = GroupMembership.find(:first, :conditions=>["entity_id=:entity_id AND group_id=:group_id",{:entity_id=>params[:entity_id], :group_id=>params[:group_id]}])
    @entity = @membership.entity
    # @campaign = @membership.entity.campaign
    if @membership.update_attributes(:role=>params[:group][:role])
      @success = true
      @notice = "Membership updated."
      @protocol = @@protocol
    else
      @notice = "Membership update failed."
      @success = false
      
    end
  end
  
  def destroy
    @user = current_user
    if params[:group_id].to_s == ""
      render :partial=>"groups_info", :locals=>{:can_edit=>current_user.can_edit_entities?(@campaign), :can_edit_groups=>current_user.edit_groups?(@campaign)}, :protocol=>@@protocol
    else
      @group = Group.find(params[:group_id])
      @entity = Entity.find(params[:entity_id])
      # @campaign = @entity.campaign
      if @group.campaign == @campaign
        @membership = GroupMembership.find(:first, :conditions=>["entity_id=:entity_id AND group_id=:group_id",{:entity_id=>@entity.id, :group_id=>@group.id}])
        if @membership.destroy
          @notice = "Successfully removed from group: #{@group.name}."
          @success = true
          @protocol = @@protocol
        else
          @success = false
          flash[:warning] = "Error removing from group: #{@group.name}."
          redirect_to :action=>:show, :id=>@entity.id, :protocol=>@@protocol
          return
        end
      end
    end
  end
  
end
