class CreateRsvpsFromContactEvents < ActiveRecord::Migration
  def self.up
    events = ContactEvent.find(:all,:conditions=>"campaign_event_id > 0")
    events.each do |event|
      rsvp = Rsvp.find(:first,:conditions=>["entity_id = :entity AND campaign_event_id = :event",{:entity=>event.entity_id, :event=>event.campaign_event_id}]) # this ought to return nil, but just in case
      if rsvp
        rsvp.update_attribute(:attended,true)
      else
        rsvp = Rsvp.new(:entity_id => event.entity_id, :campaign_event_id=>event.campaign_event_id, :attended=>true)
        rsvp.save
      end
    end
  end

  def self.down
  end
end
