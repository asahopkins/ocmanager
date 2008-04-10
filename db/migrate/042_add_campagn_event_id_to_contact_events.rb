class AddCampagnEventIdToContactEvents < ActiveRecord::Migration
  def self.up
    add_column "contact_events", "campaign_event_id", :integer
  end

  def self.down
    remove_column "contact_events", "campaign_event_id"
  end
end
