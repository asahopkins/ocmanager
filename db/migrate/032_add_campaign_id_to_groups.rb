class AddCampaignIdToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :campaign_id, :integer, :null=>false
  end

  def self.down
    remove_column :groups, :campaign_id
  end
end
