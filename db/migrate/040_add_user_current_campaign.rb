class AddUserCurrentCampaign < ActiveRecord::Migration
  def self.up
    add_column "users", "current_campaign", :integer
  end

  def self.down
    remove_column "users", "current_campaign"
  end
end
