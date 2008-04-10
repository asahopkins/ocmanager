class AddHouseholdCampaignId < ActiveRecord::Migration
  def self.up
    add_column :households, :campaign_id, :integer
  end

  def self.down
    remove_column :households, :campaign_id
  end
end
