class AddRecipientToCampaignEvent < ActiveRecord::Migration
  def self.up
    add_column :campaign_events, :recipient_committee_id, :integer
  end

  def self.down
    remove_column :campaign_events, :recipient_committee_id
  end
end
