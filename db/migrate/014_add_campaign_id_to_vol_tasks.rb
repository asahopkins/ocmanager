class AddCampaignIdToVolTasks < ActiveRecord::Migration
  def self.up
    add_column :volunteer_tasks, :campaign_id, :integer
  end

  def self.down
    remove_column :volunteer_tasks, :campaign_id
  end
end
