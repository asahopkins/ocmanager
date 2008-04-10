class AddUpdatedCreatedAtToCampaignEvents < ActiveRecord::Migration
  def self.up
    add_column "campaign_events", "created_at", :datetime
    add_column "campaign_events", "updated_at", :datetime
  end

  def self.down
    remove_column "campaign_events", "created_at"
    remove_column "campaign_events", "updated_at"
  end
end
