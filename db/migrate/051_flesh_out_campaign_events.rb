class FleshOutCampaignEvents < ActiveRecord::Migration
  def self.up
    add_column :campaign_events, :end_time, :datetime
    add_column :campaign_events, :website, :string
    add_column :campaign_events, :addr_line1, :string
    add_column :campaign_events, :addr_line2, :string
    add_column :campaign_events, :addr_city, :string
    add_column :campaign_events, :addr_state, :string
    add_column :campaign_events, :addr_zip, :string, :limit=>5
    add_column :campaign_events, :location_name, :string
    rename_column :campaign_events, :date, :start_time
  end

  def self.down
    remove_column :campaign_events, :end_time
    remove_column :campaign_events, :website
    remove_column :campaign_events, :addr_line1
    remove_column :campaign_events, :addr_line2
    remove_column :campaign_events, :addr_city
    remove_column :campaign_events, :addr_state
    remove_column :campaign_events, :addr_zip
    remove_column :campaign_events, :location_name
    rename_column :campaign_events, :start_time, :date
  end
end
