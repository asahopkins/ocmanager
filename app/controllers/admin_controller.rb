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

class AdminController < ApplicationController
  layout  'manager'
  before_filter :get_campaign
  
  def index
    @campaigns = Campaign.find(:all,:conditions=>["id IN (:ids)",{:ids=>session[:user].manager_campaigns}])
  end

  def configuration
    # @campaign = Campaign.find(params[:campaign_id])
    if !current_user.manager?(@campaign)
      flash[:warning] = "Action not permitted."
      redirect_to :controller=>"entities", :action=>"list", :protocol=>@@protocol
    end
  end
  
  def update_permissions
    
    reset_and_update_permissions()
        
    flash[:notice] = "Permissions checked and updated"
    redirect_to :action=>"index", :protocol=>@@protocol
  rescue
    flash[:notice] = "There was an error updating permissions"
    redirect_to :action=>"index", :protocol=>@@protocol
  end

  def export_all
    file_data = ""
    # tables/models: address, campaign, campaign_event, campaign_user_role, cart_item, committee, contact_event, contact_text, contribution, custom_field_value, custom_field, email_address, entity, entities_volunteer_tasks, group_field_values?, group_fields?, group_memberships, groups, household, roles, rsvps, stylesheets, taggings, tags, treasurer_entities?, users, volunteer_events, volunteer_tasks
  end
  
  
end
