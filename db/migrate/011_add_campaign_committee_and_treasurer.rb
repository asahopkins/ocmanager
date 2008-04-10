class AddCampaignCommitteeAndTreasurer < ActiveRecord::Migration
  def self.up
    create_table :campaigns, :force=>true do |t|
      t.column :name, :string
    end
    
    create_table :committees, :force=>true do |t|
      t.column :campaign_id, :integer
      t.column :name, :string
      t.column :treasurer_id, :integer
      t.column :treasurer_api_url, :string
    end
    
    create_table :treasurer_entities, :force=>true do |t|
      t.column :committee_id, :integer
      t.column :entities_id, :integer
      t.column :treasurer_id, :integer
    end
    
    remove_column :entities, :treasurer_id    
  end

  def self.down
    drop_table :campaigns
    drop_table :committees
    drop_table :treasurer_entities  
    
    add_column :entities, :treasurer_id, :integer
  end
end
