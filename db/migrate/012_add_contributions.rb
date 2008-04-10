class AddContributions < ActiveRecord::Migration
  def self.up
    create_table :contribution_recipients, :force=>true do |t|
      t.column :campaign_id, :integer
      t.column :name, :string
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end

    create_table :contributions, :force=>true do |t|
      t.column :entity_id, :integer
      t.column :contribution_recipient_id, :integer
      t.column :amount, :float
      t.column :date, :datetime
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end    
  end

  def self.down
    drop_table :contributions
    drop_table :contribution_recipients
  end
end
