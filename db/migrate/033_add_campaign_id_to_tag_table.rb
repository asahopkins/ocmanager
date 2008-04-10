class AddCampaignIdToTagTable < ActiveRecord::Migration
  def self.up
    add_column :tags, :campaign_id, :integer, :default=>0
  end

  def self.down
    remove_column :tags, :campaign_id
  end
end
