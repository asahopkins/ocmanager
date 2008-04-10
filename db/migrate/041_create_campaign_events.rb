class CreateCampaignEvents < ActiveRecord::Migration
  def self.up
    create_table :campaign_events do |t|
      t.column "campaign_id", :integer
      t.column "name", :string
      t.column "date", :datetime
      t.column "hidden", :boolean, :default=>false
    end
  end

  def self.down
    drop_table :campaign_events
  end
end
