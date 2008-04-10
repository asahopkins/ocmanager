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

# Put your code that runs your task inside the do_work method
# it will be run automatically in a thread. You have access to
# all of your rails models if you set load_rails to true in the
# config file. You also get @logger inside of this class by default.
ActionMailer::Base.template_root = File.expand_path(File.dirname(__FILE__) + "/../../app/views")

class BulkEmailWorker < BackgrounDRb::Rails
  
  attr_reader :progress
  
  def do_work(args)
    # @logger.debug args.inspect
    @progress = 0
    @text_id = args[:text_id]
    # @addresses = args[:addresses]
    @sent_entity_ids = args[:sent_entity_ids]
    @text = Email.find(@text_id)
    if @text.campaign_event_id and @text.campaign_event_id.to_i > 0
      @event = CampaignEvent.find(@text.campaign_event_id)
    end
    @entities = Entity.find(@sent_entity_ids)

    @stylesheet_id = args[:stylesheet_id]
    if @stylesheet_id
      @stylesheet = Stylesheet.find(@stylesheet_id)
    else
      @stylesheet = nil
    end

    num_addresses = @sent_entity_ids.length
    i = 1
    # @logger.debug "bar"
    # @logger.debug num_addresses.to_s
    
    @entities.each do |entity|
      begin
        email_address = entity.primary_email
        address = email_address.address
        casual_name = entity.casual_name
        unless email_address.invalid?
          # if address.include?("aol.com")
          #   email = NoBounceMailer.create_message(@text, @stylesheet, address)
          #   # @logger.debug "message created"
          #   NoBounceMailer.deliver(email)
          #   # @logger.debug "MAIL DELIVERED"
          # else
          if @stylesheet
            email = Mailer.create_message(@text, @stylesheet, address, casual_name)
          else
            email = Mailer.create_plaintext_message(@text, address, casual_name)            
          end
          # @logger.debug "message created"
          Mailer.deliver(email)
          # @logger.debug "MAIL DELIVERED"
          # end
          @logger.debug "MAIL ID: "+email.message_id.to_s
          contact_event = ContactEvent.new(:entity_id=>entity.id, :contact_text_id=>@text.id, :when_contact=>Time.now, :initiated_by=>"Campaign", :interaction=>false, :form=>"Email", :campaign_id=>@text.campaign_id, :message_id=>email.message_id.to_s)
          # @logger.debug contact_event.message_id
          contact_event.save!
          if @event # this email is an event invitation
            rsvp = entity.event_rsvp(@event)
            if rsvp
              rsvp.update_attribute(:invited, true)
            else
              rsvp = Rsvp.new(:entity_id=>entity.id, :campaign_event_id=>@event.id, :invited=>true)
              rsvp.save!
            end
          end
          # @logger.debug "event recorded"
          sleep 1
        end

        # @logger.debug "message delivered"
        @progress = ((i*100.0)/num_addresses).round
        i = i+1
        if i % 50 == 0
          sleep 30
        end
      rescue
        @logger.debug "RESCUED!"
        @logger.info "failed to deliver to address: "+ address.to_s
      end
    end
    # @logger.debug "DONE SENDING"
    # for address in @addresses
    #   # @logger.debug address.to_s
    #   # @logger.debug i.to_s+" of "+num_addresses.to_s
    #   begin
    #     email = Mailer.create_message(@text, @stylesheet, address)
    #     # @logger.debug "message created"
    #     Mailer.deliver(email)
    #     
    #     # TODO: do the contact_event here, so that we can save the message_id
    #     
    #     
    #     
    #     
    #     # @logger.debug "message delivered"
    #     @progress = ((i*100.0)/num_addresses).round
    #     i = i+1
    #     if i % 50 == 0
    #       sleep 30
    #     end
    #   rescue
    #     @logger.debug "failed to deliver to address: "+ address.to_s
    #   end
    # end
    @text.update_attribute("complete", true)
    # @sent_entity_ids.each do |entity_id|
    #   contact_event = ContactEvent.new(:entity_id=>entity_id, :contact_text_id=>@text.id, :when_contact=>Time.now, :initiated_by=>"Campaign", :interaction=>false, :form=>"Email", :campaign_id=>@text.campaign_id)
    #   contact_event.save!
    # end
    kill()
  # rescue
  #   @logger.debug "needed rescuing"
  #   kill()
  end
  
end
