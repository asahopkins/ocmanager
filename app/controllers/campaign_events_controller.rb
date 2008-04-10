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

class CampaignEventsController < ApplicationController

  layout 'manager'
  before_filter :get_campaign

  def list
    @campaign_event_pages, @campaign_events = paginate :campaign_events, :per_page => 20, :order=>'start_time DESC', :conditions=>["campaign_id=:campaign",{:campaign=>@campaign.id}] # TODO: allow hidden to be shown by admin
  end
  
  def show
    @campaign_event = CampaignEvent.find(params[:id])
    if params[:sort_by]
      entities = @campaign_event.rsvp_entities(params[:sort_by])
    else
      entities = @campaign_event.rsvp_entities      
    end
    logger.debug entities
    @entity_pages, @entities = paginate_collection entities, :per_page=>25, :page=>params[:page]
  end

  def new
    @campaign_event = CampaignEvent.new
  end

  def create
    @campaign_event = CampaignEvent.new(params[:campaign_event])
    @campaign_event.campaign = @campaign
    if @campaign_event.save
      flash[:notice] = 'Campaign Event was successfully created.'
      redirect_to :action => 'show', :id=>@campaign_event.id, :protocol=>@@protocol
    else
      render :action => 'new'
    end
  end

  def edit
    @campaign_event = CampaignEvent.find(params[:id])
  end

  def update
    @campaign_event = CampaignEvent.find(params[:id])
    if @campaign_event.update_attributes(params[:campaign_event])
      flash[:notice] = 'Campaign Event was successfully updated.'
      redirect_to :action => 'show', :id=>@campaign_event.id, :protocol=>@@protocol
    else
      render :action => 'edit'
    end
  end

  def hide
    @campaign_event = CampaignEvent.find(params[:id])
    if @campaign_event.update_attribute(:hidden, true)
      flash[:notice] = 'Campaign Event was successfully hidden.'
      redirect_to :action => 'list', :protocol=>@@protocol
    else
      render :action => 'edit'
    end
  end
  
end
