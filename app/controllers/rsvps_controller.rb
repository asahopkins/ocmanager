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

class RsvpsController < ApplicationController

  before_filter :get_campaign

  before_filter :check_entity_and_campaign, :except=>[:add_cart_to_event_attendees,:add_cart_to_event_invitees]
  
  def create
    event = CampaignEvent.find(params[:rsvp][:campaign_event_id])
    @rsvp = @entity.event_rsvp(event)
    if @rsvp
      @rsvp.update_attributes(params[:rsvp])
      if params[:rsvp][:invited] == ""
        @rsvp.update_attribute(:invited,nil)
      end
      if params[:rsvp][:attended] == ""
        @rsvp.update_attribute(:attended,nil)
      end
    else
      @rsvp = Rsvp.new(params[:rsvp])
      if params[:rsvp][:invited] == ""
        @rsvp.invited = nil
      end
      if params[:rsvp][:attended] == ""
        @rsvp.attended = nil
      end
      @rsvp.entity = @entity
      @rsvp.save!
    end
    @success = true
    @notice = "RSVP recorded."       
    @protocol = @@protocol
    @recent_events = @campaign.get_recent_events
    @rsvp_pages, @rsvps = paginate :rsvps, :per_page => 5, :order=>"campaign_events.start_time DESC, updated_at DESC", :conditions=>["entity_id=:entity", {:entity=>@entity.id}], :include=>:campaign_event
  # TODO: what to do if the RSVP doesn't save
  # rescue
    # @success = false
    # @notice = "RSVP save failed"
    # @protocol = @@protocol
    # @recent_events = @campaign.get_recent_events
    # @rsvp_pages, @rsvps = paginate :rsvps, :per_page => 5, :order=>"campaign_event.start_time DESC, updated_at DESC", :conditions=>["entity_id=:entity", {:entity=>@entity.id}], :include=>:campaign_event
  end
  
  alias update create
  
  def list
    @recent_events = @campaign.get_recent_events
    @rsvp_pages, @rsvps = paginate :rsvps, :per_page => 5, :order=>"campaign_events.start_time DESC, updated_at DESC", :conditions=>["entity_id=:entity", {:entity=>@entity.id}], :include=>:campaign_event
    render :partial=>'entities/event_rsvps', :protocol=>@@protocol    
  end

  def destroy
    rsvps = Rsvp.find(:all, :conditions=>["campaign_event_id = :c_e AND entity_id = :ent", {:c_e=>params[:campaign_event_id], :ent=>params[:entity_id]}])
    rsvp_id = rsvps[0].id
    rsvps.each do |rsvp|
      rsvp.destroy
    end
    if params[:referring_page] == "event_show"
      render :update do |page|
        page.remove "entity_line_#{params[:entity_id]}"
        page.replace_html "flash_notice", "Attendance record removed."
        page.visual_effect :highlight, "flash_notice"
      end
    else
      render :update do |page|
        page.remove "rsvp_#{rsvp_id}"
        page.replace_html "rsvps_notice", "Attendance record removed."
        page.visual_effect :highlight, "rsvps_notice"
      end
    end
  end

  def add_cart_to_event_attendees
    campaign_event = CampaignEvent.find(params[:campaign_event][:id])
    entities = current_user.entities
    Rsvp.transaction do
      entities.each do |entity|
        rsvp = Rsvp.find(:first,:conditions=>["campaign_event_id = :c_e AND entity_id = :ent", {:c_e=>campaign_event.id, :ent=>entity.id}])
        if rsvp
          rsvp.update_attribute('attended',true)
        else
          rsvp = Rsvp.new(:entity_id=>entity.id, :campaign_event_id=>campaign_event.id,:attended=>true)
          rsvp.save!
        end
      end
    end
    render :update do |page|
      page.replace_html "flash_notice", "MyPeople added as attendees of event: #{campaign_event.name}"
      page.visual_effect :highlight, 'flash_notice'
    end
  # rescue    
  end

  def add_cart_to_event_invitees
    campaign_event = CampaignEvent.find(params[:campaign_event][:id])
    entities = current_user.entities
    Rsvp.transaction do
      entities.each do |entity|
        rsvp = Rsvp.find(:first,:conditions=>["campaign_event_id = :c_e AND entity_id = :ent", {:c_e=>campaign_event.id, :ent=>entity.id}])
        if rsvp
          rsvp.update_attribute('invited',true)
        else
          rsvp = Rsvp.new(:entity_id=>entity.id, :campaign_event_id=>campaign_event.id,:invited=>true)
          rsvp.save!
        end
      end
    end
    render :update do |page|
      page.replace_html "flash_notice", "MyPeople added as invited to event: #{campaign_event.name}"
      page.visual_effect :highlight, 'flash_notice'
    end
  # rescue    
  end
  
  protected
  
  def check_entity_and_campaign
    if params[:entity_id]
      @entity = Entity.find(params[:entity_id])
    elsif params[:id]
      @entity = Entity.find(params[:id])
    else
      @entity = nil
      @campaign = nil
      render :partial=>"user/not_available"
      return      
    end
    unless @entity.campaign_id == @campaign.id
      @entity = nil
      @campaign = nil
      render :partial=>"user/not_available"
      return
    end
  end

end
