class AddCampaignIdsToContactsEventsTextsAndStylesheets < ActiveRecord::Migration
  def self.up
    add_column "contact_texts", "campaign_id", :integer
    add_column "stylesheets", "campaign_id", :integer
    add_column "contact_events", "campaign_id", :integer
  end

  def self.down
    remove_column "contact_texts", "campaign_id"
    remove_column "stylesheets", "campaign_id"
    remove_column "contact_events", "campaign_id"    
  end
end
