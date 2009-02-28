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
    @campaign_events = CampaignEvent.paginate :per_page => 20, :order=>'start_time DESC', :conditions=>["campaign_id=:campaign",{:campaign=>@campaign.id}],:page=>params[:page] # TODO: allow hidden to be shown by admin
  end
  
  def show
    # TODO contribution and pledge and response ordering are variously screwed up
    @campaign_event = CampaignEvent.find(params[:id])
    unless params[:page].to_i > 1
      params[:page] = 1
    end
    unless params[:sort_by]
      params[:sort_by] = "name"
    end
    case params[:sort_by]
    when "name"
      @entities = Entity.paginate :per_page=>10, :page=>params[:page], :include=>[:rsvps, :contact_events, :contributions], :conditions=>["entities.campaign_id = :campaign AND (contact_events.campaign_event_id = :event_id OR rsvps.campaign_event_id = :event_id OR contributions.campaign_event_id = :event_id)",{:event_id=>@campaign_event.id, :campaign=>@campaign.id}], :order=>"entities.last_name ASC, entities.name ASC, entities.first_name ASC"
    when "invited"
      @entities = Entity.paginate :per_page=>10, :page=>params[:page], :include=>[:rsvps, :contact_events, :contributions], :conditions=>["entities.campaign_id = :campaign AND (contact_events.campaign_event_id = :event_id OR rsvps.campaign_event_id = :event_id OR contributions.campaign_event_id = :event_id)",{:event_id=>@campaign_event.id, :campaign=>@campaign.id}], :order=>"rsvps.invited ASC, entities.last_name ASC, entities.name ASC, entities.first_name ASC"      
    when "attendance"
      @entities = Entity.paginate :per_page=>10, :page=>params[:page], :include=>[:rsvps, :contact_events, :contributions], :conditions=>["entities.campaign_id = :campaign AND (contact_events.campaign_event_id = :event_id OR rsvps.campaign_event_id = :event_id OR contributions.campaign_event_id = :event_id)",{:event_id=>@campaign_event.id, :campaign=>@campaign.id}], :order=>"rsvps.attended ASC, entities.last_name ASC, entities.name ASC, entities.first_name ASC"      
    when "response"
      @entities = Entity.paginate :per_page=>10, :page=>params[:page], :include=>[:rsvps, :contact_events, :contributions], :conditions=>["entities.campaign_id = :campaign AND (contact_events.campaign_event_id = :event_id OR rsvps.campaign_event_id = :event_id OR contributions.campaign_event_id = :event_id)",{:event_id=>@campaign_event.id, :campaign=>@campaign.id}], :order=>"rsvps.response DESC, entities.last_name ASC, entities.name ASC, entities.first_name ASC"      
    when "pledge"
      @entities = Entity.paginate :per_page=>10, :page=>params[:page], :include=>[:rsvps, :contact_events, :contributions], :conditions=>["entities.campaign_id = :campaign AND (contact_events.campaign_event_id = :event_id OR rsvps.campaign_event_id = :event_id OR contributions.campaign_event_id = :event_id)",{:event_id=>@campaign_event.id, :campaign=>@campaign.id}], :order=>"contact_events.pledge_value DESC, contact_events.will_contribute DESC, entities.last_name ASC, entities.name ASC, entities.first_name ASC"     
    when "contribution"
      @entities = Entity.paginate :per_page=>10, :page=>params[:page], :include=>[:rsvps, :contact_events, :contributions], :conditions=>["entities.campaign_id = :campaign AND (contact_events.campaign_event_id = :event_id OR rsvps.campaign_event_id = :event_id OR contributions.campaign_event_id = :event_id)",{:event_id=>@campaign_event.id, :campaign=>@campaign.id}], :order=>"contributions.amount DESC, contact_events.will_contribute DESC, entities.last_name ASC, entities.name ASC, entities.first_name ASC"     
    else
      @entities = Entity.paginate :per_page=>10, :page=>params[:page], :include=>[:rsvps, :contact_events, :contributions], :conditions=>["entities.campaign_id = :campaign AND (contact_events.campaign_event_id = :event_id OR rsvps.campaign_event_id = :event_id OR contributions.campaign_event_id = :event_id)",{:event_id=>@campaign_event.id, :campaign=>@campaign.id}], :order=>"entities.last_name ASC, entities.name ASC, entities.first_name ASC"
    end
    # if params[:sort_by]
    #   entities = @campaign_event.rsvp_entities(params[:sort_by])
    # else
    #   entities = @campaign_event.rsvp_entities      
    # end
    # logger.debug entities
    # @entities = paginate_collection entities, :per_page=>25, :page=>params[:page]
    @in_mypeople = build_in_mypeople @entities
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
