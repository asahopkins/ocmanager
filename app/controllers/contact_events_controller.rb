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

class ContactEventsController < ApplicationController

  before_filter :get_campaign
  # TODO: before_filters for checkinbg entity against campaign

  before_filter :check_entity_and_campaign, :except=>[:add_cart_to_event_attendees]
  
  def list
    # @entity = Entity.find(params[:id])
    # @campaign = @entity.campaign
    @recent_texts = @campaign.get_recent_texts
    @recent_events = @campaign.get_recent_events
    @contact_event_pages, @contact_events = paginate :contact_events, :per_page => 5, :order=>"when_contact DESC", :conditions=>["entity_id=:entity", {:entity=>@entity.id}]
    render :partial=>'entities/contact_events', :protocol=>@@protocol    
  end

  def create
    # @entity = Entity.find(params[:id])
    # @campaign = @entity.campaign
    logger.debug params[:contact_event]
    @contact_event = ContactEvent.new(params[:contact_event])
    @contact_event.entity_id = @entity.id
    @contact_event.campaign_id = @campaign.id
    @contact_events = @entity.contact_events.sort{|a,b| b.when_contact <=> a.when_contact} #sorted from latest to earliest
    most_recent = true
    if @contact_events[0] and @contact_events[0].when_contact > @contact_event.when_contact
      most_recent = false
    end
    # if @contact_event.form == "Email" or @contact_event.form == "Mail"
    #   @contact_event.interaction = false
    # end
    if !@contact_event.will_contribute?
      @contact_event.pledge_value = nil
    end
    if !@contact_event.will_volunteer?
      @contact_event.how_volunteer = nil
      @contact_event.when_volunteer_text = nil
      @contact_event.when_volunteer = nil
    end
    if @contact_event.requires_followup?
      @entity.update_attribute(:followup_required, true)
    else
      @contact_event.future_contact_date = nil
      if @contact_event.interaction? and most_recent
        @entity.update_attribute(:followup_required, false)
      end
    end
    @contact_event.save!

    @recent_texts = @campaign.get_recent_texts
    @recent_events = @campaign.get_recent_events

    @contact_event_pages, @contact_events = paginate :contact_events, :per_page => 5, :order=>"when_contact DESC, updated_at DESC", :conditions=>["entity_id=:entity", {:entity=>@entity.id}]
    @success = true
    @protocol = @@protocol
    @notice = "Contact report created." 
  # rescue
  #   @success = false
  #   @protocol = @@protocol
  #   @notice = "Contact report creation failed." 
  end

  def update
    # @entity = Entity.find(params[:entity_id])
    # @campaign = @entity.campaign
    @contact_event = ContactEvent.find(params[:contact_event][:id])
    if params[:contact_event][:contact_id].to_s != ""
      
    end
    if @contact_event.update_attributes(params[:contact_event])
      # if @contact_event.form == "Email" or @contact_event.form == "Mail"
      #   @contact_event.interaction = false
      # end
      if !@contact_event.will_contribute?
        @contact_event.pledge_value = nil
      end
      if !@contact_event.will_volunteer?
        @contact_event.how_volunteer = nil
        @contact_event.when_volunteer_text = nil
        @contact_event.when_volunteer = nil
      end
      if @contact_event.requires_followup?
        @entity.update_attribute(:followup_required, true)
      else
        @contact_event.future_contact_date = nil
        interaction_events = []
        @entity.contact_events.each do |event|
          interaction_events << event if event.interaction?
        end
        interaction_events = interaction_events.sort{|a,b| b.when_contact <=> a.when_contact} #sorted from latest to earliest
        most_recent = true # WITH INTERACTION
        if interaction_events[0] and interaction_events[0].when_contact > @contact_event.when_contact
          most_recent = false
        end
        if @contact_event.interaction? and most_recent
          @entity.update_attribute(:followup_required, false)
        end
      end
      @contact_event.save!
      @recent_texts = @campaign.get_recent_texts
      @recent_events = @campaign.get_recent_events
      @contact_event_pages, @contact_events = paginate :contact_events, :per_page => 5, :order=>"when_contact DESC, updated_at DESC", :conditions=>["entity_id=:entity", {:entity=>@entity.id}]
      @success = true
      @protocol = @@protocol
      @notice = "Contact report updated." 
    else
      @success = false
      @notice = "Contact report update failed."
    end
  end

  def destroy
    # @entity = Entity.find(params[:entity_id])
    # @campaign = @entity.campaign
    @contact_event = ContactEvent.find(params[:id])
    if @contact_event.entity_id == @entity.id
      @contact_events = @entity.contact_events.sort{|a,b| b.when_contact <=> a.when_contact} #sorted from latest to earliest
      logger.debug @contact_events
      @contact_events.delete(@contact_event)
      logger.debug @contact_events
      @contact_events.each do |event|
        if event.requires_followup?
          logger.debug "followup required"
          @entity.update_attributes('followup_required'=>true)
          break
        end
        if event.interaction?
          logger.debug "no followup required"
          @entity.update_attributes('followup_required'=>false)
          break
        end
      end

      logger.debug "about to destroy event"
      @contact_event.destroy

      @all_texts = @campaign.contact_texts
      @recent_texts = @campaign.get_recent_texts
      @recent_events = @campaign.get_recent_events
      @contact_event_pages, @contact_events = paginate :contact_events, :per_page => 5, :order=>"when_contact DESC, updated_at DESC", :conditions=>["entity_id=:entity", {:entity=>@entity.id}]
      @success = true
      @protocol = @@protocol
      @notice = "Contact report deleted." 
    else
      raise "entity mismatch"
    end
    
  rescue
    @success = false
    @protocol = @@protocol
    @notice = "Contact report deletion failed." 
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
